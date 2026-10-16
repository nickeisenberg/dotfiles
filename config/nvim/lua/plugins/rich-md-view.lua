local is_win = vim.fn.has("win32") == 1

-- The viewer's own venv: ~/.local/share/nvim/rich-md-view/venv on Unix,
-- %LOCALAPPDATA%\nvim-data\rich-md-view\venv on Windows. Defined here so
-- `build` and `config` agree on it.
local venv = vim.fs.joinpath(vim.fn.stdpath("data"), "rich-md-view", "venv")
local venv_python = is_win and vim.fs.joinpath(venv, "Scripts", "python.exe")
  or vim.fs.joinpath(venv, "bin", "python")

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

return {
  dir = "rich-md-view.nvim",
  config = function()
    require("rich-md-view").setup({ python = venv_python })
  end,
  build = function(plugin)
    if not vim.uv.fs_stat(venv_python) then
      plugin.run(vim.list_extend(base_python(), { "-m", "venv", venv }))
    end
    -- The venv's python runs pip, so no activate script is needed.
    plugin.run({ venv_python, "-m", "pip", "install", "." })
  end,
}
