-- Installing the viewer's Python dependencies into a venv of its own.

local M = {}

local is_win = vim.fn.has("win32") == 1

-- lua/rich-md-view/build.lua -> plugin root
M.root = vim.fs.dirname(
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
)

---Where the venv goes by default: ~/.local/share/nvim/rich-md-view/venv on
---Unix, %LOCALAPPDATA%\nvim-data\rich-md-view\venv on Windows.
M.default_venv = vim.fs.joinpath(vim.fn.stdpath("data"), "rich-md-view", "venv")

---The interpreter inside the venv at `venv` (default: `default_venv`).
---@param venv? string
---@return string
function M.venv_python(venv)
  venv = vim.fs.normalize(venv or M.default_venv)
  return is_win and vim.fs.joinpath(venv, "Scripts", "python.exe")
    or vim.fs.joinpath(venv, "bin", "python")
end

-- An interpreter to create the venv with: `python` from the options, or
-- the first one found. On Windows `py` comes first: a bare `python` there
-- can be the Microsoft Store stub.
local function base_python(python)
  if python then
    local cmd = type(python) == "string" and { python } or vim.deepcopy(python)
    cmd[1] = vim.fs.normalize(cmd[1])
    if vim.fn.executable(cmd[1]) == 0 then
      error(("python `%s` is not executable"):format(cmd[1]), 0)
    end
    return cmd
  end

  local candidates = is_win and { { "py", "-3" }, { "python" } }
    or { { "python3.12" }, { "python3" } }
  for _, cmd in ipairs(candidates) do
    if vim.fn.executable(cmd[1]) == 1 then
      return cmd
    end
  end
  error("no Python 3 interpreter found", 0)
end

-- Outside pack.nvim's async build, run commands synchronously.
local function run_sync(cmd)
  local res = vim.system(cmd, { cwd = M.root, text = true }):wait()
  if res.code ~= 0 then
    error(
      ("`%s` exited with %d:\n%s"):format(
        table.concat(cmd, " "),
        res.code,
        vim.trim(res.stdout .. res.stderr)
      ),
      0
    )
  end
  return res
end

-- The installation behind an interpreter: a venv's python and the python
-- that made it give the same prefix and version, so only a real switch
-- differs.
local function base_of(run, cmd)
  local probe = vim.list_extend(vim.deepcopy(cmd), {
    "-c",
    "import os, sys; print(os.path.realpath(sys.base_prefix), sys.version)",
  })
  return vim.trim(run(probe).stdout)
end

---@class RichMdView.BuildOpts
---@field python? string|string[] Interpreter to create the venv with, as a
---path or an argv list (`{ "py", "-3.13" }`). Default: `python3.12`, then
---`python3` (`py -3`, then `python` on Windows).
---@field venv? string Where to make the venv. Default: `default_venv`. Give
---`setup()` the same `venv` so the viewer runs from it.

---Create the venv if needed, then pip install the plugin into it. If
---`opts.python` names a different installation than the one the venv was
---made with, the venv is made again.
---Usable as a pack.nvim `build` function; with no `plugin`, it runs
---synchronously.
---@param plugin? { run: fun(cmd: string[]): vim.SystemCompleted }
---@param opts? RichMdView.BuildOpts
function M.run(plugin, opts)
  opts = opts or {}
  local run = plugin and plugin.run or run_sync
  local venv = vim.fs.normalize(opts.venv or M.default_venv)
  local python = M.venv_python(venv)

  if not vim.uv.fs_stat(python) then
    run(vim.list_extend(base_python(opts.python), { "-m", "venv", venv }))
  elseif opts.python then
    -- Without `opts.python`, any existing venv will do. With it, a venv made
    -- by another installation is made again. `--clear` only here: `venv`
    -- is known to be a venv, so emptying it can't remove anything else.
    local base = base_python(opts.python)
    if base_of(run, { python }) ~= base_of(run, base) then
      run(vim.list_extend(base, { "-m", "venv", "--clear", venv }))
    end
  end

  -- The venv's python runs pip, so no activate script is needed.
  run({ python, "-m", "pip", "install", M.root })
end

return M
