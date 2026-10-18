-- A split beside a directory buffer showing the entry under the cursor,
-- following the cursor. It shows the real thing: a file's own buffer, or a
-- directory's own directory buffer, so you can go in and edit, or browse
-- from there. Going in doesn't move the preview: it still follows the
-- cursor of the window it belongs to.
--
-- A buffer loaded only to be previewed is wiped when the preview moves on,
-- unless you went into it or changed it.

local fs = require("files.fs")
local view = require("files.view")

local M = {}

-- owner window -> { win, path, loaded = a buffer loaded only to show }
local previews = {}

local function binary(path)
  local file = io.open(path, "rb")
  if not file then
    return false
  end
  local head = file:read(8192) or ""
  file:close()
  return head:find("\0", 1, true) ~= nil
end

local function scratch(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  return buf
end

local function loaded(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.api.nvim_buf_get_name(buf) == name
    then
      return true
    end
  end
  return false
end

-- Wipe a buffer the preview loaded, if nothing else needs it.
local function drop(buf)
  if
    buf
    and vim.api.nvim_buf_is_valid(buf)
    and not vim.bo[buf].modified
    and #vim.fn.win_findbuf(buf) == 0
  then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

local function show(p, path)
  local before = p.loaded
  p.loaded = nil
  if not fs.is_dir(path) and binary(path) then
    vim.api.nvim_win_set_buf(p.win, scratch({ "(binary file)" }))
  else
    local name = fs.is_dir(path) and view.name(path) or path
    local was_loaded = loaded(name)
    local ok = vim.api.nvim_win_call(p.win, function()
      local shortmess = vim.o.shortmess
      vim.opt.shortmess:append("A") -- no prompt for an existing swap file
      local done =
        pcall(vim.cmd, "keepalt keepjumps edit " .. vim.fn.fnameescape(name))
      vim.o.shortmess = shortmess
      return done
    end)
    -- Only claim a buffer that is really the one asked for.
    local buf = vim.api.nvim_win_get_buf(p.win)
    if ok and not was_loaded and vim.api.nvim_buf_get_name(buf) == name then
      p.loaded = buf
    end
  end
  p.path = path
  if before ~= p.loaded then
    drop(before)
  end
end

-- Show the entry under the cursor, if this window has a preview.
local function follow()
  local p = previews[vim.api.nvim_get_current_win()]
  if not (p and vim.api.nvim_win_is_valid(p.win)) then
    return
  end
  local path = view.path_at(vim.api.nvim_get_current_line())
  if path and path ~= p.path then
    show(p, path)
  end
end

-- For CursorMoved. Done after the event: run from an autocmd, the :edit
-- would load the buffer without its own autocmds (filetype, LSP, reading
-- a directory), as autocmds don't nest.
function M.update()
  vim.schedule(follow)
end

function M.close(owner)
  local p = previews[owner]
  previews[owner] = nil
  if not p then
    return
  end
  if vim.api.nvim_win_is_valid(p.win) then
    vim.api.nvim_win_close(p.win, true)
  end
  drop(p.loaded)
end

-- Open a preview beside the current window (below it when it is narrow),
-- or close its preview.
function M.toggle()
  local owner = vim.api.nvim_get_current_win()
  if previews[owner] then
    M.close(owner)
    return
  end
  local wide = vim.api.nvim_win_get_width(owner) >= 80
  local win = vim.api.nvim_open_win(
    scratch({}),
    false,
    { split = wide and "right" or "below", win = owner }
  )
  previews[owner] = { win = win }
  follow()
end

-- Going into a preview makes what it shows yours: it won't be wiped.
function M.on_win_enter()
  local win = vim.api.nvim_get_current_win()
  for _, p in pairs(previews) do
    if p.win == win then
      p.loaded = nil
    end
  end
end

-- An owner window that leaves directory buffers loses its preview.
function M.on_buf_enter()
  local owner = vim.api.nvim_get_current_win()
  if previews[owner] and not view.dir(0) then
    M.close(owner)
  end
end

function M.on_win_closed(win)
  for owner, p in pairs(previews) do
    if win == owner or win == p.win then
      M.close(owner)
    end
  end
end

return M
