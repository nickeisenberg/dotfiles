-- Turning a raw spec, as written in a spec file, into a normalized one.

local config = require("pack.config")

local M = {}

local function to_src(s)
  if s:match("^%a[%w+.-]*://") or s:match("^git@") then
    return s
  end
  return config.options.base_url .. s
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
    spec.name = spec.name or (spec.src:gsub("%.git$", "")):match("[^/]+$")
  end
  spec[1] = nil

  return spec
end

-- A table is a list of specs when its first item is a table, or when it is
-- a plain list of several strings. `{ "a/b", config = ... }` is one spec.
function M.is_list(raw)
  return type(raw) == "table"
    and (type(raw[1]) == "table" or (vim.islist(raw) and #raw > 1))
end

return M
