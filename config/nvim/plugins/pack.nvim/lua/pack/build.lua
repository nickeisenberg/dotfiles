-- Running a spec's `build` after its plugin is installed or updated.

local config = require("pack.config")
local registry = require("pack.registry")

local M = {}

-- 'shellcmdflag' rather than "-c", so cmd.exe, PowerShell and fish work too.
local function shell_argv(cmd)
  local argv = { vim.o.shell }
  vim.list_extend(
    argv,
    vim.split(vim.o.shellcmdflag, "%s+", { trimempty = true })
  )
  argv[#argv + 1] = cmd
  return argv
end

local function report(spec, ok, output)
  if ok then
    config.notify("built " .. spec.name)
  else
    config.notify(
      ("build failed for %s:\n%s"):format(spec.name, output),
      vim.log.levels.ERROR
    )
  end
end

---@param spec table
---@param path string where the plugin is on disk
---@param active? boolean whether the plugin is already on 'runtimepath'
function M.run(spec, path, active)
  local build = spec.build

  if type(build) == "string" and build:sub(1, 1) ~= ":" then
    config.notify("building " .. spec.name)
    vim.system(shell_argv(build), { cwd = path }, function(res)
      -- Many tools print their errors to stdout, so show both streams.
      local output = vim.trim((res.stdout or "") .. (res.stderr or ""))
      vim.schedule(function()
        report(spec, res.code == 0, output)
      end)
    end)
    return
  end

  -- Vim commands and functions rely on the plugin's code being loaded.
  -- Local plugins are always on 'runtimepath'; remote ones may not be yet.
  if not spec.path and not active then
    vim.cmd.packadd(spec.name)
  end
  local ok, err = pcall(function()
    if type(build) == "function" then
      build({ spec = spec, path = path })
    else
      vim.cmd(build:sub(2))
    end
  end)
  report(spec, ok, err)
end

---Run the builds of `names`, or of every spec that has one.
---@param names? string[]
function M.run_all(names)
  local specs = names
      and vim.tbl_map(function(name)
        return registry.by_name[name] or { name = name }
      end, names)
    or registry.plugins

  for _, spec in ipairs(specs) do
    if not spec.build then
      if names then
        config.notify(spec.name .. " has no build", vim.log.levels.WARN)
      end
    elseif spec.path then
      M.run(spec, spec.path, true)
    else
      local ok, got = pcall(vim.pack.get, { spec.name }, { info = false })
      if ok and got[1] then
        M.run(spec, got[1].path, got[1].active)
      else
        config.notify(spec.name .. " is not installed", vim.log.levels.WARN)
      end
    end
  end
end

---Must run before vim.pack.add() so builds run on first install.
function M.setup()
  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("pack_build", { clear = true }),
    callback = function(ev)
      local data = ev.data
      if data.kind ~= "install" and data.kind ~= "update" then
        return
      end
      -- The full spec rides along in vim.pack's `data` field; plugins added
      -- with vim.pack.add() directly have none.
      local spec = data.spec.data
      if type(spec) == "table" and spec.build then
        M.run(spec, data.path, data.active)
      end
    end,
  })
end

return M
