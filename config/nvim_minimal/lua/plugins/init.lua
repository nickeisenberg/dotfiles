---@param name string
---@return nil
--- Adds local packages defined in 'vim.fn.stdpath("config") .. "/plugins/"'
local function add_local_pkgs(name)
  local plugin_root = vim.fn.stdpath("config") .. "/plugins/"
  vim.opt.runtimepath:prepend(plugin_root .. name)
end

add_local_pkgs("picker.nvim")
add_local_pkgs("float-term.nvim")

-- Add git repo plugins.
vim.pack.add({
  {
    src = "https://github.com/Vigemus/iron.nvim",
  },
  {
    src = "https://github.com/lewis6991/gitsigns.nvim",
  },
  {
    src = "https://github.com/stevearc/oil.nvim",
  },
  {
    src = "https://github.com/refractalize/oil-git-status.nvim",
  },
  {
    src = "https://github.com/lervag/vimtex",
  },
})

require("plugins.picker")
require("plugins.iron")
require("plugins.gitsigns")
require("plugins.float-term")
require("plugins.oil")
require("plugins.vimtex")
