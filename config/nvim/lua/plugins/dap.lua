return {
  {
    "mfussenegger/nvim-dap",
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
