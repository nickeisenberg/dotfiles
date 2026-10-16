-- Running a spec's `build` after its plugin is installed or updated.

local config = require("pack.config")
local registry = require("pack.registry")

local M = {}

-- 'shell' can carry arguments ("/bin/bash --login"), so split it like
-- Neovim does. 'shellcmdflag' rather than "-c", so cmd.exe, PowerShell and
-- fish work too.
local function shell_argv(cmd)
  local argv = vim.split(vim.o.shell, "%s+", { trimempty = true })
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

-- Many tools print their errors to stdout, so show both streams.
local function output_of(res)
  return vim.trim((res.stdout or "") .. (res.stderr or ""))
end

local function run_shell(spec, path)
  config.notify("building " .. spec.name)
  -- vim.system() throws when the shell can't be started at all.
  local ok, err = pcall(
    vim.system,
    shell_argv(spec.build),
    { cwd = path },
    function(res)
      vim.schedule(function()
        report(spec, res.code == 0, output_of(res))
      end)
    end
  )
  if not ok then
    report(spec, false, err)
  end
end

local function run_vim_cmd(spec)
  local ok, err = pcall(vim.cmd, spec.build:sub(2))
  report(spec, ok, err)
end

-- A failed plugin.run() raises one of these. Its message already says what
-- went wrong, so it is reported without a Lua traceback.
local CommandError = {}

local function traceback(err)
  if getmetatable(err) == CommandError then
    return err.message
  end
  return debug.traceback(err, 1)
end

-- Function builds run as a coroutine. plugin.run() starts a process and
-- yields; the process's exit callback resumes the coroutine, so the build
-- reads like blocking code but Neovim keeps running while it waits.
local function run_function(spec, path)
  local co

  -- Resume the build, and report once it has finished: either it returned
  -- or it raised an error. While it is suspended in plugin.run() there is
  -- nothing to report yet.
  local function step(...)
    local resumed, built, err = coroutine.resume(co, ...)
    if coroutine.status(co) ~= "dead" then
      return
    end
    if not resumed then
      report(spec, false, built)
    else
      report(spec, built, err)
    end
  end

  local plugin = { spec = spec, path = path }

  ---Run `cmd` (an argv list, no shell) and return its vim.SystemCompleted.
  ---Raises an error if it exits non-zero. `opts` go to vim.system();
  ---`cwd` defaults to the plugin root.
  function plugin.run(cmd, opts)
    if coroutine.running() ~= co then
      error("pack: plugin.run() only works inside the build function", 2)
    end
    opts = vim.tbl_extend("force", { cwd = path, text = true }, opts or {})

    -- The exit callback runs in a fast event, where most of the API is off
    -- limits; vim.schedule() resumes the build on the main loop instead.
    local started, err = pcall(vim.system, cmd, opts, function(res)
      vim.schedule(function()
        step(res)
      end)
    end)
    if not started then
      error(setmetatable({ message = err }, CommandError))
    end

    local res = coroutine.yield()
    if res.code ~= 0 then
      error(setmetatable({
        message = ("`%s` exited with %d:\n%s"):format(
          table.concat(cmd, " "),
          res.code,
          output_of(res)
        ),
      }, CommandError))
    end
    return res
  end

  co = coroutine.create(function()
    -- xpcall inside the coroutine, so a traceback still has the build's
    -- frames. LuaJIT can yield across it.
    return xpcall(spec.build, traceback, plugin)
  end)

  config.notify("building " .. spec.name)
  step()
end

---@param spec table
---@param path string where the plugin is on disk
---@param active? boolean whether the plugin is already on 'runtimepath'
function M.run(spec, path, active)
  local build = spec.build

  if type(build) == "string" and build:sub(1, 1) ~= ":" then
    run_shell(spec, path)
    return
  end

  -- Vim commands and functions rely on the plugin's code being loaded.
  -- Local plugins are always on 'runtimepath'; remote ones may not be yet.
  if not spec.path and not active then
    vim.cmd.packadd(spec.name)
  end
  if type(build) == "function" then
    run_function(spec, path)
  else
    run_vim_cmd(spec)
  end
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
