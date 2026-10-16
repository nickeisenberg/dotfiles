-- Collecting specs from the spec files into one ordered list.

local config = require("pack.config")
local Spec = require("pack.spec")

local M = {}

---Resolved specs in load order.
M.plugins = {}

---Resolved specs by name.
M.by_name = {}

-- Names with `enabled = false` anywhere, and who pulled a name in as a dep.
local disabled, required_by = {}, {}

-- Cleared in place, so references handed out by `require("pack")` stay valid.
local function reset()
  for _, t in ipairs({ M.plugins, M.by_name, disabled, required_by }) do
    for k in pairs(t) do
      t[k] = nil
    end
  end
end

---@param raw any a spec, or a list of specs
---@param parent? string name of the spec that lists `raw` in its `deps`
function M.add(raw, parent)
  if Spec.is_list(raw) then
    for _, r in ipairs(raw) do
      M.add(r, parent)
    end
    return
  end

  local spec = Spec.normalize(raw)
  if parent then
    required_by[spec.name] = required_by[spec.name] or parent
  end
  if spec.enabled == false then
    disabled[spec.name] = true
    return
  end

  for _, dep in ipairs(spec.deps or {}) do
    M.add(dep, spec.name)
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

-- `enabled = false` wins even when another spec lists the plugin in `deps`,
-- which may have been read before the spec that disables it.
local function drop_disabled()
  for i = #M.plugins, 1, -1 do
    local name = M.plugins[i].name
    if disabled[name] then
      table.remove(M.plugins, i)
      M.by_name[name] = nil
      if required_by[name] then
        config.notify(
          ("%s is disabled, but %s depends on it"):format(
            name,
            required_by[name]
          ),
          vim.log.levels.WARN
        )
      end
    end
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
  reset()

  for _, mod in ipairs(spec_modules()) do
    local ok, err = pcall(function()
      local ret = require(mod)
      if type(ret) == "table" or type(ret) == "string" then
        M.add(ret)
      end
    end)
    if not ok then
      config.notify(
        ("failed to load %s:\n%s"):format(mod, err),
        vim.log.levels.ERROR
      )
    end
  end

  drop_disabled()
end

return M
