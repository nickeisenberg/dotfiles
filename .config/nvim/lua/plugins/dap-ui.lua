return {
  "rcarriga/nvim-dap-ui",
  dependencies = {
    "mfussenegger/nvim-dap"
  },
  keys = {
  	{
  	  "<leader>du",
  		function() require("dapui").toggle() end,
  		desc = "Toggle Debugger UI",
  	},
  },
  -- automatically open/close the DAP UI when starting/stopping the debugger
  config = function()
    local dapui = require("dapui")
    dapui.setup()

    local dap = require("dap")

    -- dap.listeners.before.attach.dapui_config = function()
    --   dapui.open()
    -- end
    -- dap.listeners.before.launch.dapui_config = function()
    --   dapui.open()
    -- end
    -- dap.listeners.before.event_terminated.dapui_config = function()
    --   dapui.close()
    -- end
    -- dap.listeners.before.event_exited.dapui_config = function()
    --   dapui.close()
    -- end
  end,
}
