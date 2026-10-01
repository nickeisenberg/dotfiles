---@param name string
---@return nil
--- Adds local packages defined in 'vim.fn.stdpath("config") .. "/plugins/"'
local function add_local_pkgs(name)
  local plugin_root = vim.fn.stdpath("config") .. "/plugins/"
  vim.opt.runtimepath:prepend(plugin_root .. name)
end

add_local_pkgs("picker.nvim")
add_local_pkgs("float-term.nvim")

-- NVIM_PLUGIN_HOST: eg github, gitlab
local plugin_host = vim.env.NVIM_PLUGIN_HOST:gsub("/+$", "")

---@param repo string
---@return string
local function gh(repo)
  return plugin_host .. "/" .. repo
end

-- Add git repo plugins.
vim.pack.add({
  {
    src = gh("Vigemus/iron.nvim"),
  },
  {
    src = gh("lewis6991/gitsigns.nvim"),
  },
  {
    src = gh("stevearc/oil.nvim"),
  },
  {
    src = gh("refractalize/oil-git-status.nvim"),
  },
  {
    src = gh("lervag/vimtex"),
  },
  {
    src = gh("folke/snacks.nvim"),
  },
  {
    src = gh("coder/claudecode.nvim"),
  },
})

require("plugins.claudecode")
require("plugins.picker")
require("plugins.iron")
require("plugins.gitsigns")
require("plugins.float-term")
require("plugins.oil")
require("plugins.vimtex")
