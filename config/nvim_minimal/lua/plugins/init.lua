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
    src = "https://www.github.com/Vigemus/iron.nvim",
  },
  {
    src = "https://www.github.com/lewis6991/gitsigns.nvim",
  },
  {
    src = "https://www.github.com/tpope/vim-fugitive",
  },
  {
    src = "https://www.github.com/stevearc/oil.nvim",
  },
  {
    src = "https://www.github.com/refractalize/oil-git-status.nvim",
  },
  {
    src = "https://www.github.com/lervag/vimtex",
  },
  {
    src = "https://www.github.com/folke/snacks.nvim",
  },
  {
    src = "https://www.github.com/coder/claudecode.nvim",
  },
})

require("plugins.claudecode")
require("plugins.picker")
require("plugins.iron")
require("plugins.gitsigns")
require("plugins.float-term")
require("plugins.oil")
require("plugins.vimtex")
