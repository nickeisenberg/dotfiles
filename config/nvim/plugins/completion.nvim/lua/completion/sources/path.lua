-- Path source: completes file and directory names once the text before
-- the cursor contains a "/".
--
-- complete() follows the 'completefunc' protocol (|complete-functions|),
-- so it can sit in 'complete' as an F{func} source.

local config = require("completion.config")

local M = {}

-- Quotes, whitespace and brackets end a path.
local PATH_TOKEN = [[[^%s"'`%(%)%[%]{}<>]*/[^%s"'`%(%)%[%]{}<>/]*$]]

local function line_before_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return vim.api.nvim_get_current_line():sub(1, col)
end

-- Turn the typed directory ("~/x/", "./x/", "x/", "/x/") into one that
-- can be scanned. The typed form is kept for the inserted text.
local function resolve(dir)
  if dir:match("^[~$]") then
    return vim.fn.expand(dir)
  end
  if dir:sub(1, 1) == "/" then
    return dir
  end

  local base
  if config.options.path.relative_to == "buffer" then
    local name = vim.api.nvim_buf_get_name(0)
    base = name ~= "" and vim.fs.dirname(name) or nil
  end
  return (base or vim.fn.getcwd()) .. "/" .. dir
end

local function scan(dir, prefix)
  local handle = vim.uv.fs_scandir(resolve(dir))
  if not handle then
    return {}
  end

  local show_hidden = config.options.path.hidden or prefix:sub(1, 1) == "."
  local entries = {}
  while true do
    local name, kind = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if show_hidden or name:sub(1, 1) ~= "." then
      entries[#entries + 1] = { name = name, is_dir = kind == "directory" }
    end
  end

  -- Directories first, then by name.
  table.sort(entries, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    return a.name < b.name
  end)
  return entries
end

local function matches(entries, prefix)
  if prefix == "" then
    return entries
  end
  if config.options.fuzzy then
    return vim.fn.matchfuzzy(entries, prefix, { key = "name" })
  end
  return vim.tbl_filter(function(e)
    return e.name:sub(1, #prefix) == prefix
  end, entries)
end

---@param findstart integer
---@param base string
---@return integer|table
function M.complete(findstart, base)
  if findstart == 1 then
    local line = line_before_cursor()
    local token = line:match(PATH_TOKEN)
    -- -3: not a path here; leave this source out.
    return token and #line - #token or -3
  end

  local dir, prefix = base:match("^(.*/)([^/]*)$")
  if not dir then
    return {}
  end

  local items = {}
  for _, e in ipairs(matches(scan(dir, prefix), prefix)) do
    items[#items + 1] = {
      word = dir .. e.name,
      abbr = e.name .. (e.is_dir and "/" or ""),
      kind = e.is_dir and "Folder" or "File",
      menu = "[path]",
    }
  end
  return items
end

return M
