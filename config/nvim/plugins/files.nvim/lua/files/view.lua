-- Directory buffers, named files:///abs/dir/: one line per entry, "/12
-- name" with the number hidden, and a trailing / on directories.

local config = require("files.config")
local fs = require("files.fs")
local index = require("files.index")

local M = {}

local ns = vim.api.nvim_create_namespace("files")

-- bufnr -> { dir, ids }: ids are the entries as last read from disk, so a
-- missing one was deleted.
local buffers = {}

M.scheme = "files://"

---@param dir string an absolute path without a trailing /
function M.name(dir)
  return M.scheme .. (dir == "/" and "/" or dir .. "/")
end

---@return string? dir the directory a buffer shows
function M.dir(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr):match("^files://(.*)$")
  if not path then
    return nil
  end
  return path == "/" and path or (path:gsub("/$", ""))
end

---@return table? state see `buffers`
function M.state(bufnr)
  return buffers[bufnr]
end

-- Every directory buffer still open.
function M.list()
  return vim.tbl_filter(vim.api.nvim_buf_is_loaded, vim.tbl_keys(buffers))
end

function M.forget(bufnr)
  buffers[bufnr] = nil
end

-- A line as an entry: its number (nil on a line you typed), its name, and
-- whether it is a directory. The "../" line is { parent = true }: it goes
-- up a level and is never a change to save.
---@return { id: integer?, name: string, dir: boolean, parent: boolean? }?
function M.parse(line)
  -- The space after the number may have been deleted; no name starts with
  -- a /, so the number is still the number.
  local id, rest = line:match("^/(%d+) ?(.*)$")
  id = tonumber(id)
  -- A name as read from disk is kept exactly ("a " stays "a "); one you
  -- typed is trimmed.
  local name = rest or line
  local path = id and index.path(id)
  if not (path and name:gsub("/+$", "") == vim.fs.basename(path)) then
    name = vim.trim(name)
  end
  if name == "" then
    return nil
  end
  local dir = name:sub(-1) == "/"
  name = name:gsub("/+$", "")
  return { id = id, name = name, dir = dir, parent = name == ".." }
end

-- The path a line of the current buffer stands for, or nil when it is new
-- or renamed and not saved yet.
---@return string?
function M.path_at(line)
  local entry = M.parse(line)
  if entry and entry.parent then
    return vim.fs.dirname(M.dir(0))
  end
  local path = entry and entry.id and index.path(entry.id)
  if path and vim.fs.basename(path) == entry.name then
    return path
  end
end

-- The 0-based column a line's name starts at, after the hidden number.
local function name_col(line)
  local col = line:match("^/%d+ ?()")
  return col and col - 1 or 0
end

-- Keep the cursor off the hidden number, where typing would break it.
function M.constrain_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local min = name_col(vim.api.nvim_get_current_line())
  if col < min then
    vim.api.nvim_win_set_cursor(0, { row, min })
  end
end

-- The window options a directory buffer needs, local to it in `win`.
function M.set_window(win, git)
  local function set(name, value)
    vim.api.nvim_set_option_value(name, value, { scope = "local", win = win })
  end
  set("conceallevel", 3)
  set("concealcursor", "nvic")
  set("wrap", false)
  if git then
    set("signcolumn", "yes:1")
  end
end

-- Read the directory into the buffer, as one change that can't be undone,
-- keeping the cursor on the entry it was on.
function M.render(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local dir = M.dir(bufnr)
  local entries, err = fs.read_dir(dir)
  if not entries then
    return false, err
  end

  -- A buffer line can't hold a newline, so a name with one is left out
  -- (said once, not on every re-read).
  local shown = vim.tbl_filter(function(e)
    return not e.name:find("\n")
  end, entries)
  if #shown < #entries and not buffers[bufnr] then
    config.notify(
      ("%s: not showing names with a newline"):format(dir),
      vim.log.levels.WARN
    )
  end

  local win = vim.fn.bufwinid(bufnr)
  local row = win ~= -1 and vim.api.nvim_win_get_cursor(win)[1] or 1
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
  local entry = M.parse(line or "")
  local focus = entry and entry.name

  -- "../" first, except at the root.
  local lines, ids, focus_row = {}, {}, nil
  if dir ~= "/" then
    lines[1] = "../"
  end
  for _, e in ipairs(shown) do
    local id = index.id(dir == "/" and "/" .. e.name or dir .. "/" .. e.name)
    ids[#ids + 1] = id
    lines[#lines + 1] = ("/%d %s%s"):format(id, e.name, e.dir and "/" or "")
    if e.name == focus then
      focus_row = #lines
    end
  end

  local undolevels = vim.bo[bufnr].undolevels
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].undolevels = undolevels
  vim.bo[bufnr].modified = false
  buffers[bufnr] = { dir = dir, ids = ids }

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, line in ipairs(lines) do
    if line:sub(-1) == "/" then
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, name_col(line), {
        end_col = #line,
        hl_group = "FilesDirectory",
      })
    end
  end

  if win ~= -1 and #lines > 0 then
    row = focus_row or math.min(row, #lines)
    vim.api.nvim_win_set_cursor(win, { row, name_col(lines[row]) })
  end
  return true
end

-- Put the cursor on the entry called `name`, if there is one.
function M.focus(name)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local entry = M.parse(line)
    if entry and entry.name == name then
      vim.api.nvim_win_set_cursor(0, { i, name_col(line) })
      return
    end
  end
end

-- Set up a new directory buffer. `keymaps` maps keys to functions.
function M.init(bufnr, keymaps)
  vim.bo[bufnr].buftype = "acwrite" -- :w runs BufWriteCmd
  vim.bo[bufnr].bufhidden = "hide" -- keep edits while you visit another
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "files" -- syntax/files.vim hides the numbers
  for lhs, fn in pairs(keymaps) do
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, nowait = true })
  end
end

return M
