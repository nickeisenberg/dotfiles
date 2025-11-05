local M = {
  {
    "mfussenegger/nvim-dap",
    branch = "master",
    commit = "7367cec8e8f7a0b1e4566af9a7ef5959d11206a7",
	  keys = {
	  	{
	  		"<leader>dc",
	  		function()
          require("dap").continue()
        end,
	  		desc = "Start/Continue Debugger",
	  	},
	  	{
	  		"<leader>db",
	  		function() require("dap").toggle_breakpoint() end,
	  		desc = "Add Breakpoint",
	  	},
	  	{
	  		"<leader>dt",
	  		function() require("dap").terminate() end,
	  		desc = "Terminate Debugger",
	  	},
	  },
  },

  {
    "rcarriga/nvim-dap-ui",
    branch = "master",
    commit ="cf91d5e2d07c72903d052f5207511bf7ecdb7122",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio"
    },
    keys = {
    	{
    	  "<leader>du",
    		function() require("dapui").toggle() end,
    		desc = "Toggle Debugger UI",
    	},
    },
    opts = {}
  },

  {
    "mfussenegger/nvim-dap-python",
    branch = "master",
    commit = "bfe572e4458e0ac876b9539a1e9f301c72db8ea0",
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      local function isWindowsOS()
          return package.config:sub(1,1) == '\\'
      end
      local debugpyPythonPath
      if not isWindowsOS() then
        debugpyPythonPath = os.getenv("HOME") .. "/.sysvenv/venv/bin/python"
      else
        debugpyPythonPath = "C:\\Users\\nicke\\venvs\\debugpy\\Scripts\\python.exe"
      end
    	require("dap-python").setup(debugpyPythonPath)
    end,
  }
}

return {}
