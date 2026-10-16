-- Snippet source: your own snippets, from VSCode-style JSON files.
--
--   snippets/python.json
--   {
--     "main guard": {
--       "prefix": "main",
--       "body": ["if __name__ == \"__main__\":", "\t${1:main()}"],
--       "description": "Run only as a script"
--     }
--   }
--
-- complete() is an F{func} source like the path one; accepting one of its
-- items swaps the prefix for the body and expands it with vim.snippet.

local config = require("completion.config")

local M = {}

-- path -> { mtime = integer, snippets = table[] }. A file is read again
-- only after it changes, so edited snippets show up without a restart.
local cache = {}

local function read(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    cache[path] = nil
    return {}
  end

  local hit = cache[path]
  if hit and hit.mtime == stat.mtime.sec then
    return hit.snippets
  end

  local snippets = {}
  local file = io.open(path, "r")
  local text = file and file:read("*a")
  if file then
    file:close()
  end

  local ok, decoded = pcall(vim.json.decode, text or "")
  if not ok or type(decoded) ~= "table" then
    config.notify("can't read snippets in " .. path, vim.log.levels.WARN)
    decoded = {}
  end

  for name, s in pairs(decoded) do
    local body = type(s.body) == "table" and table.concat(s.body, "\n")
      or s.body
    local prefixes = type(s.prefix) == "table" and s.prefix or { s.prefix }
    for _, prefix in ipairs(prefixes) do
      if type(prefix) == "string" and type(body) == "string" then
        snippets[#snippets + 1] = {
          prefix = prefix,
          body = body,
          description = s.description or name,
        }
      end
    end
  end

  cache[path] = { mtime = stat.mtime.sec, snippets = snippets }
  return snippets
end

-- Snippets for a filetype: its own file, the ones it extends, and all.json.
local function for_filetype(ft)
  local opts = config.options.snippets
  local fts = { ft, unpack(opts.extends[ft] or {}) }
  fts[#fts + 1] = "all"

  local out = {}
  for _, dir in ipairs(opts.paths) do
    for _, name in ipairs(fts) do
      vim.list_extend(out, read(vim.fs.joinpath(dir, name .. ".json")))
    end
  end
  return out
end

local function matches(snippets, base)
  if base == "" then
    return snippets
  end
  if config.options.fuzzy then
    return vim.fn.matchfuzzy(snippets, base, { key = "prefix" })
  end
  return vim.tbl_filter(function(s)
    return s.prefix:sub(1, #base) == base
  end, snippets)
end

---@param findstart integer
---@param base string
---@return integer|table
function M.complete(findstart, base)
  if findstart == 1 then
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line():sub(1, col)
    local start = vim.fn.match(line, [[\k*$]])
    -- -3: no word typed yet, so offer nothing rather than every snippet.
    return start < col and start or -3
  end

  local items = {}
  for _, s in ipairs(matches(for_filetype(vim.bo.filetype), base)) do
    items[#items + 1] = {
      word = s.prefix,
      kind = "Snippet",
      menu = "[snip]",
      info = s.description .. "\n\n" .. s.body,
      dup = 1,
      user_data = { completion_snippet = s.body },
    }
  end
  return items
end

-- On accept, replace the inserted prefix with the expanded body.
function M.expand_on_accept()
  if vim.v.event.reason ~= "accept" then
    return
  end
  local item = vim.v.completed_item
  local body = vim.tbl_get(item, "user_data", "completion_snippet")
  if not body then
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local start = col - #item.word
  vim.api.nvim_buf_set_text(0, row - 1, start, row - 1, col, {})
  vim.api.nvim_win_set_cursor(0, { row, start })
  vim.snippet.expand(body)
end

return M
