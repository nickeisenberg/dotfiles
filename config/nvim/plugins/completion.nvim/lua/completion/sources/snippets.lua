-- Snippet source: snippets from VSCode-style JSON files.
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
-- A snippet directory is laid out one of two ways:
--   - plain: <filetype>.json, plus all.json for every filetype
--   - a VSCode snippet extension (friendly-snippets, say): a package.json
--     whose contributes.snippets lists { language, path } pairs, with the
--     files anywhere below it. "all" is a language there too.
-- A package.json in the directory picks the second; the snippet files
-- themselves are the same either way.
--
-- complete() is an F{func} source like the path one; accepting one of its
-- items swaps the prefix for the body and expands it with vim.snippet.

local config = require("completion.config")

local M = {}

-- path -> { mtime = integer, value = any }. A file is read and parsed
-- again only after it changes, so edits show up without a restart.
local cache = {}

-- Decode the JSON file at `path` and pass it through `parse`, cached.
-- A missing file gives `fallback`.
local function load(path, parse, fallback)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    cache[path] = nil
    return fallback
  end

  local hit = cache[path]
  if hit and hit.mtime == stat.mtime.sec then
    return hit.value
  end

  local file = io.open(path, "r")
  local text = file and file:read("*a")
  if file then
    file:close()
  end

  local ok, decoded = pcall(vim.json.decode, text or "")
  if not ok or type(decoded) ~= "table" then
    config.notify("can't read " .. path, vim.log.levels.WARN)
    decoded = {}
  end

  local value = parse(decoded, path)
  cache[path] = { mtime = stat.mtime.sec, value = value }
  return value
end

local function join_lines(v)
  return type(v) == "table" and table.concat(v, "\n") or v
end

-- A snippet file -> a flat list of { prefix, body, description }; a
-- snippet with several prefixes gives one entry per prefix.
local function parse_snippets(decoded)
  local snippets = {}
  for name, s in pairs(decoded) do
    local body = join_lines(s.body)
    local prefixes = type(s.prefix) == "table" and s.prefix or { s.prefix }
    for _, prefix in ipairs(prefixes) do
      if type(prefix) == "string" and type(body) == "string" then
        snippets[#snippets + 1] = {
          prefix = prefix,
          body = body,
          description = join_lines(s.description) or name,
        }
      end
    end
  end
  return snippets
end

-- A package.json -> language -> snippet file paths.
local function parse_manifest(decoded, path)
  local dir = vim.fs.dirname(path)
  local by_language = {}
  local entries = vim.tbl_get(decoded, "contributes", "snippets") or {}
  for _, entry in ipairs(entries) do
    local languages = type(entry.language) == "table" and entry.language
      or { entry.language }
    for _, language in ipairs(languages) do
      by_language[language] = by_language[language] or {}
      table.insert(
        by_language[language],
        vim.fs.normalize(vim.fs.joinpath(dir, entry.path))
      )
    end
  end
  return by_language
end

-- The snippet files in `dir` for each name in `names`.
local function files_in(dir, names)
  local manifest = load(vim.fs.joinpath(dir, "package.json"), parse_manifest)
  local files = {}
  for _, name in ipairs(names) do
    if manifest then
      vim.list_extend(files, manifest[name] or {})
    else
      files[#files + 1] = vim.fs.joinpath(dir, name .. ".json")
    end
  end
  return files
end

-- Snippets for a filetype: its own, the filetypes it extends, and "all".
local function for_filetype(ft)
  local opts = config.options.snippets
  local names = { ft, unpack(opts.extends[ft] or {}) }
  names[#names + 1] = "all"

  local out, seen = {}, {}
  for _, dir in ipairs(opts.paths) do
    for _, file in ipairs(files_in(vim.fs.normalize(dir), names)) do
      -- One file can be listed under several of the names.
      if not seen[file] then
        seen[file] = true
        vim.list_extend(out, load(file, parse_snippets, {}))
      end
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

-- Neovim's snippet parser rejects a placeholder that holds text and
-- another tabstop, like ${3:yield $4} or ${2:raise $1}, though the LSP
-- grammar allows it. This drops tabstops nested inside a placeholder and
-- keeps their default text: ${3:yield $4} -> ${3:yield },
-- ${1:a ${2:b}} -> ${1:a b}. Top-level tabstops are untouched.
local function flatten(body)
  local out, depth, i = {}, 0, 1
  -- One entry per open "${": whether its closing "}" is kept.
  local open = {}

  while i <= #body do
    local c = body:sub(i, i)

    if c == "\\" then
      out[#out + 1] = body:sub(i, i + 1)
      i = i + 2
    elseif body:match("^%${%d+:", i) then
      local head = body:match("^%${%d+:", i)
      local keep = depth == 0
      if keep then
        out[#out + 1] = head
      end
      open[#open + 1] = keep
      depth = depth + 1
      i = i + #head
    elseif depth > 0 and body:match("^%$%d+", i) then
      i = i + #body:match("^%$%d+", i) -- nested $N: drop
    elseif depth > 0 and body:match("^%${%d+}", i) then
      i = i + #body:match("^%${%d+}", i) -- nested ${N}: drop
    elseif c == "}" and depth > 0 then
      if table.remove(open) then
        out[#out + 1] = c
      end
      depth = depth - 1
      i = i + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end

  return table.concat(out)
end

-- Expand `body` at the cursor, falling back to a flattened body when
-- Neovim can't parse it. Returns false when neither parses; nothing is
-- inserted then, since parsing happens before any text changes.
---@param body string
---@return boolean
function M.expand(body)
  if pcall(vim.snippet.expand, body) then
    return true
  end
  return (pcall(vim.snippet.expand, flatten(body)))
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

  if not M.expand(body) then
    -- Put the prefix back so accepting never loses text.
    vim.api.nvim_buf_set_text(0, row - 1, start, row - 1, start, { item.word })
    vim.api.nvim_win_set_cursor(0, { row, col })
    config.notify(
      "can't expand snippet '" .. item.word .. "'",
      vim.log.levels.WARN
    )
  end
end

return M
