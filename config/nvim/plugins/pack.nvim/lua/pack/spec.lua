-- Turning a raw spec, as written in a spec file, into a normalized one.

local config = require("pack.config")

local M = {}

local function to_src(s)
  if s:match("^%a[%w+.-]*://") or s:match("^git@") then
    return s
  end
  return config.options.base_url .. s
end

-- "https://host/owner/repo.git/" and "git@host:repo.git" both give "repo".
local function infer_name(src)
  local s = (src:gsub("/+$", ""))
  s = (s:gsub("%.git$", ""))
  return s:match("[^/:]+$")
end

---@return table spec with `name` and either `src` (remote) or `path` (local)
function M.normalize(raw)
  if type(raw) == "string" then
    raw = { raw }
  end
  local spec = vim.tbl_extend("force", {}, raw)

  -- Paths like "/abc", "~/abc" or "./abc" are shorthand for `dir`.
  if not spec.dir and type(spec[1]) == "string" and spec[1]:match("^[/~.]") then
    spec.dir = spec[1]
  end

  if spec.dir then
    local path = vim.fs.normalize(spec.dir)
    if path:sub(1, 1) ~= "/" then
      path = config.options.local_dir .. "/" .. path
    end
    spec.path = path
    spec.name = spec.name or vim.fs.basename(path)
  else
    local src = spec.src or spec[1]
    assert(type(src) == "string", "pack: spec has no source")
    spec.src = to_src(src)
    spec.name = spec.name or infer_name(spec.src)
    assert(spec.name, "pack: can't infer a name from " .. spec.src)
  end
  spec[1] = nil

  return spec
end

-- A table is a list of specs when its first item is a table, or when it
-- has several positional items. `{ "a/b", config = ... }` is one spec.
-- A list can't also carry options: in `{ "a/b", "c/d", config = f }` it is
-- unclear which plugin `config` belongs to, so that is an error.
function M.is_list(raw)
  if type(raw) ~= "table" then
    return false
  end
  if type(raw[1]) ~= "table" and raw[2] == nil then
    return false
  end
  if not vim.islist(raw) then
    error(
      ("pack: spec list starting with %s also has options; "):format(
        vim.inspect(raw[1])
      ) .. "give each plugin its own table",
      0
    )
  end
  return true
end

return M
