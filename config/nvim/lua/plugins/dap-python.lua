return {
  "mfussenegger/nvim-dap-python",
  dependencies = "mfussenegger/nvim-dap",
  config = function()
    local debugpyPythonPath = os.getenv("HOME") .. "/.venv311/debugpy/bin/python"
    print(debugpyPythonPath)
  	require("dap-python").setup(debugpyPythonPath)
  end,
}
