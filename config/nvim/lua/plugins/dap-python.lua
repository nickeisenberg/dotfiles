return {
  "mfussenegger/nvim-dap-python",
  dependencies = "mfussenegger/nvim-dap",
  config = function()

    function isWindowsOS()
        return package.config:sub(1,1) == '\\'
    end
    
    if not isWindowsOS() then
      local debugpyPythonPath = os.getenv("HOME") .. "/.venv311/debugpy/bin/python"
    else
      local debugpyPythonPath = "C:\\Users\\nicke\\venvs\\debugpy\\Scripts\\python.exe"
    end

    print(debugpyPythonPath)
  	require("dap-python").setup(debugpyPythonPath)
  end,
}
