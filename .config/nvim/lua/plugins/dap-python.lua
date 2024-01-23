return {
  "mfussenegger/nvim-dap-python",
  dependencies = "mfussenegger/nvim-dap",
  config = function()
    local debugpyPythonPath = "/home/nicholas/.venv/debugpy/bin/python"
    print(debugpyPythonPath)
  	require("dap-python").setup(debugpyPythonPath)
  end,
}
