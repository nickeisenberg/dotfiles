-- A thin wrapper around vim.pack. See README.md for the spec format.

local build = require("pack.build")
local commands = require("pack.commands")
local config = require("pack.config")
local registry = require("pack.registry")

local M = {}

M.config = config.options
M.plugins = registry.plugins
M.by_name = registry.by_name

local function add_local(spec)
  vim.opt.runtimepath:prepend(spec.path)
  local after = spec.path .. "/after"
  if vim.uv.fs_stat(after) then
    vim.opt.runtimepath:append(after)
  end
end

local function run_configs()
  for _, spec in ipairs(registry.plugins) do
    if spec.config then
      local ok, err = xpcall(spec.config, debug.traceback, spec)
      if not ok then
        config.notify(
          ("config failed for %s:\n%s"):format(spec.name, err),
          vim.log.levels.ERROR
        )
      end
    end
  end
end

---@param opts? table
function M.setup(opts)
  M.config = config.setup(opts)
  registry.collect()
  build.setup()

  local remote = {}
  for _, spec in ipairs(registry.plugins) do
    if spec.path then
      add_local(spec)
    else
      remote[#remote + 1] = {
        src = spec.src,
        name = spec.name,
        version = spec.version,
        -- Handed back in PackChanged events, for the build hook.
        data = spec,
      }
    end
  end
  vim.pack.add(remote)

  run_configs()
  commands.setup()
end

return M
