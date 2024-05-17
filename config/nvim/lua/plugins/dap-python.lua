return {
  "mfussenegger/nvim-dap-python",
  dependencies = "mfussenegger/nvim-dap",
  config = function()

    function isWindowsOS()
        return package.config:sub(1,1) == '\\'
    end

    local debugpyPythonPath
    if not isWindowsOS() then
      debugpyPythonPath = os.getenv("HOME") .. "/.venv311/debugpy/bin/python"
    else
      debugpyPythonPath = "C:\\Users\\nicke\\venvs\\debugpy\\Scripts\\python.exe"
    end

  	require("dap-python").setup(debugpyPythonPath)
  end,
}
