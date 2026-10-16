-- Installing the viewer's Python dependencies into a venv of its own.

local M = {}

local is_win = vim.fn.has("win32") == 1

-- lua/rich-md-view/build.lua -> plugin root
M.root = vim.fs.dirname(
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
)

-- ~/.local/share/nvim/rich-md-view/venv on Unix,
-- %LOCALAPPDATA%\nvim-data\rich-md-view\venv on Windows.
M.venv = vim.fs.joinpath(vim.fn.stdpath("data"), "rich-md-view", "venv")

---The venv's interpreter; the default `python` once it exists.
M.python = is_win and vim.fs.joinpath(M.venv, "Scripts", "python.exe")
  or vim.fs.joinpath(M.venv, "bin", "python")

-- An interpreter to create the venv with. On Windows `py` comes first: a
-- bare `python` there can be the Microsoft Store stub.
local function base_python()
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

---Create the venv if needed, then pip install the plugin into it.
---Usable as a pack.nvim `build` function; called with no argument, it runs
---synchronously.
---@param plugin? { run: fun(cmd: string[]) }
function M.run(plugin)
  local run = plugin and plugin.run or run_sync
  if not vim.uv.fs_stat(M.python) then
    run(vim.list_extend(base_python(), { "-m", "venv", M.venv }))
  end
  -- The venv's python runs pip, so no activate script is needed.
  run({ M.python, "-m", "pip", "install", M.root })
end

return M
