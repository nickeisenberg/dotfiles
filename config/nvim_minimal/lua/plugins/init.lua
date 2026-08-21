-- lua/plugins/init.lua

-- Add locally developed plugins.
local plugin_root = vim.fn.stdpath("config") .. "/plugins"
vim.opt.runtimepath:prepend(plugin_root .. "/picker.nvim")

-- Add git repo plugins.
vim.pack.add({
  {
    src = "https://github.com/Vigemus/iron.nvim",
  },
  {
    src = "https://github.com/lewis6991/gitsigns.nvim",
  },
})

require("plugins.picker")
require("plugins.iron")
require("plugins.gitsigns")
