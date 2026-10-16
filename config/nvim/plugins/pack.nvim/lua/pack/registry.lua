-- Collecting specs from the spec files into one ordered list.

local config = require("pack.config")
local Spec = require("pack.spec")

local M = {}

---Resolved specs in load order.
M.plugins = {}

---Resolved specs by name.
M.by_name = {}

function M.add(raw)
  if Spec.is_list(raw) then
    for _, r in ipairs(raw) do
      M.add(r)
    end
    return
  end

  local spec = Spec.normalize(raw)
  if spec.enabled == false then
    return
  end

  for _, dep in ipairs(spec.deps or {}) do
    M.add(dep)
  end

  -- A plugin listed both as a dependency and on its own is merged.
  local existing = M.by_name[spec.name]
  if existing then
    for k, v in pairs(spec) do
      if existing[k] == nil then
        existing[k] = v
      end
    end
  else
    M.by_name[spec.name] = spec
    M.plugins[#M.plugins + 1] = spec
  end
end

local function spec_modules()
  local import = config.options.import
  local dir = vim.fn.stdpath("config") .. "/lua/" .. import:gsub("%.", "/")

  local mods = {}
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:match("%.lua$") and name ~= "init.lua" then
      mods[#mods + 1] = import .. "." .. name:gsub("%.lua$", "")
    end
  end
  table.sort(mods)

  return mods
end

---Require every spec file and add what it returns.
function M.collect()
  for _, mod in ipairs(spec_modules()) do
    local ok, ret = pcall(require, mod)
    if not ok then
      config.notify(
        ("failed to load %s:\n%s"):format(mod, ret),
        vim.log.levels.ERROR
      )
    elseif type(ret) == "table" or type(ret) == "string" then
      M.add(ret)
    end
  end
end

return M
