-- Directory buffers, named files:///abs/dir/: one line per entry, "/12
-- name" with the number hidden, and a trailing / on directories.

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
-- whether it is a directory.
---@return { id: integer?, name: string, dir: boolean }?
function M.parse(line)
  local id, rest = line:match("^/(%d+) (.*)$")
  local name = vim.trim(rest or line)
  if name == "" then
    return nil
  end
  local dir = name:sub(-1) == "/"
  return { id = tonumber(id), name = (name:gsub("/+$", "")), dir = dir }
end

-- The path a line stands for, or nil when it is new or renamed and not
-- saved yet.
---@return string?
function M.path_at(line)
  local entry = M.parse(line)
  local path = entry and entry.id and index.path(entry.id)
  if path and vim.fs.basename(path) == entry.name then
    return path
  end
end

-- The 0-based column a line's name starts at, after the hidden number.
local function name_col(line)
  local col = line:match("^/%d+ ()")
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
-- and put the cursor on `focus` (a name), or where it was.
function M.render(bufnr, focus)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local dir = M.dir(bufnr)
  local entries, err = fs.read_dir(dir)
  if not entries then
    return false, err
  end

  local win = vim.fn.bufwinid(bufnr)
  local row = win ~= -1 and vim.api.nvim_win_get_cursor(win)[1] or 1
  if not focus then
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local entry = M.parse(line or "")
    focus = entry and entry.name
  end

  local lines, ids, focus_row = {}, {}, nil
  for i, e in ipairs(entries) do
    local id = index.id(dir == "/" and "/" .. e.name or dir .. "/" .. e.name)
    ids[i] = id
    lines[i] = ("/%d %s%s"):format(id, e.name, e.dir and "/" or "")
    if e.name == focus then
      focus_row = i
    end
  end

  local undolevels = vim.bo[bufnr].undolevels
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].undolevels = undolevels
  vim.bo[bufnr].modified = false
  buffers[bufnr] = { dir = dir, ids = ids }

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, e in ipairs(entries) do
    if e.dir then
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, name_col(lines[i]), {
        end_col = #lines[i],
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

-- Set up a new directory buffer. `keymaps` maps keys to functions.
function M.init(bufnr, keymaps)
  vim.bo[bufnr].buftype = "acwrite" -- :w runs BufWriteCmd
  vim.bo[bufnr].bufhidden = "hide" -- keep edits while you visit another
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "files"
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd([[syntax match FilesId /^\/\d\+ / conceal]])
  end)
  for lhs, fn in pairs(keymaps) do
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, nowait = true })
  end
end

return M
