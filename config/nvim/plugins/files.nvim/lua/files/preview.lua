-- A split beside a directory buffer showing the entry under the cursor,
-- following the cursor. The file isn't opened: its start is read into a
-- scratch buffer and highlighted, so no LSP or file autocmds run.

local fs = require("files.fs")
local view = require("files.view")

local M = {}

local MAX_BYTES = 256 * 1024

-- While open: { win, owner = the directory buffer's window, path }.
local state

function M.is_open()
  return state ~= nil and vim.api.nvim_win_is_valid(state.win)
end

-- The preview's lines and filetype for `path`.
local function contents(path)
  if fs.is_dir(path) then
    local entries = fs.read_dir(path) or {}
    return vim.tbl_map(function(e)
      return e.name .. (e.dir and "/" or "")
    end, entries)
  end
  local file = io.open(path, "rb")
  if not file then
    return { "(can't read)" }
  end
  local data = file:read(MAX_BYTES) or ""
  file:close()
  if data:find("\0", 1, true) then
    return { "(binary file)" }
  end
  local lines = vim.split(data, "\r?\n")
  if lines[#lines] == "" then
    lines[#lines] = nil -- the final newline
  end
  return lines, vim.filetype.match({ filename = path, contents = lines })
end

local function show(path)
  local lines, filetype = contents(path)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  if filetype then
    local lang = vim.treesitter.language.get_lang(filetype)
    if not (lang and pcall(vim.treesitter.start, buf, lang)) then
      vim.bo[buf].syntax = filetype
    end
  end
  vim.api.nvim_win_set_buf(state.win, buf)
  state.path = path
end

-- Show the entry under the cursor, if the preview belongs to this window.
function M.update()
  if not M.is_open() or vim.api.nvim_get_current_win() ~= state.owner then
    return
  end
  local path = view.path_at(vim.api.nvim_get_current_line())
  if path and path ~= state.path then
    show(path)
  end
end

function M.close()
  if M.is_open() then
    vim.api.nvim_win_close(state.win, true)
  end
  state = nil
end

-- Open beside the current window (below it when it is narrow), or close.
function M.toggle()
  if M.is_open() then
    M.close()
    return
  end
  local owner = vim.api.nvim_get_current_win()
  local wide = vim.api.nvim_win_get_width(owner) >= 80
  local win = vim.api.nvim_open_win(
    vim.api.nvim_create_buf(false, true),
    false,
    { split = wide and "right" or "below", win = owner }
  )
  state = { win = win, owner = owner }
  M.update()
end

-- Close when the owner window leaves directory buffers or closes.
function M.on_buf_enter()
  if
    M.is_open()
    and vim.api.nvim_get_current_win() == state.owner
    and not view.dir(0)
  then
    M.close()
  end
end

function M.on_win_closed(win)
  if state and (win == state.owner or win == state.win) then
    M.close()
  end
end

return M
