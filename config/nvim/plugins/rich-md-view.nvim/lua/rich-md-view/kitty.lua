-- Kitty graphics protocol, spoken by kitty and ghostty (from iron.nvim).
-- Images are uploaded straight to the host terminal and placed with
-- Unicode placeholders, which the viewer prints as regular terminal text.

local M = {}

local esc = string.char(27)
local chunk_size = 4096

local function in_tmux()
  return (vim.env.TMUX or "") ~= ""
    or (vim.env.TERM or ""):match("^tmux") ~= nil
end

-- Writes one graphics command to the host terminal.
local function write(body)
  local sequence = esc .. "_G" .. body .. esc .. "\\"
  if in_tmux() then
    local escaped = sequence:gsub(esc, esc .. esc)
    sequence = esc .. "Ptmux;" .. escaped .. esc .. "\\"
  end
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(sequence)
  else
    vim.api.nvim_chan_send(vim.v.stderr, sequence)
  end
end

---Whether the host terminal looks like it speaks the protocol.
-- Set by terminals without Unicode placeholder support. Kitty's and
-- ghostty's own variables leak into any terminal started from them, so
-- these are checked first.
local other_terminal = {
  "ALACRITTY_WINDOW_ID",
  "ALACRITTY_SOCKET",
  "WEZTERM_EXECUTABLE",
  "KONSOLE_VERSION",
  "VTE_VERSION",
}

local function set(name)
  return (vim.env[name] or "") ~= ""
end

---@return boolean
function M.detect()
  local term = vim.env.TERM or ""
  -- TERM is always set by the terminal itself, so it can't have leaked.
  if term == "xterm-kitty" or term == "xterm-ghostty" then
    return true
  end
  if term == "alacritty" or vim.iter(other_terminal):any(set) then
    return false
  end
  return vim.env.TERM_PROGRAM == "ghostty"
    or set("KITTY_WINDOW_ID")
    or set("GHOSTTY_RESOURCES_DIR")
end

---Reason the protocol can't be used right now, if any.
---@return string?
function M.check()
  if not vim.o.termguicolors then
    -- Placeholders carry the image id in their 24-bit foreground color.
    return "termguicolors is required"
  end
end

---Uploads a PNG and creates its virtual placement.
---@param id integer
---@param png string
---@param rows integer
---@param cols integer
function M.render(id, png, rows, cols)
  local data = vim.base64.encode(png)
  for offset = 1, #data, chunk_size do
    local header = offset == 1 and ("a=t,f=100,t=d,i=%d,q=2,"):format(id) or ""
    local more = offset + chunk_size <= #data and 1 or 0
    local chunk = data:sub(offset, offset + chunk_size - 1)
    write(header .. ("m=%d;%s"):format(more, chunk))
  end
  write(("a=p,U=1,i=%d,c=%d,r=%d,C=1,q=2"):format(id, cols, rows))
end

---Frees an image in the host terminal.
---@param id integer
function M.delete(id)
  write(("a=d,d=I,i=%d,q=2"):format(id))
end

return M
