vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load configuration.
require("lsp")
require("colorscheme")
require("autocommands")
require("keymaps")
require("options")

-- Load plugins: every file in lua/plugins/ returns a spec for pack.nvim.
-- Local plugins are shared by work/ and personal/ in the sibling plugins/
-- directory, found by resolving the ~/.config/nvim symlink.
local config_dir = vim.uv.fs_realpath(vim.fn.stdpath("config"))
local plugins_dir = vim.fs.dirname(config_dir) .. "/plugins"
vim.opt.runtimepath:prepend(plugins_dir .. "/pack.nvim")
require("pack").setup({ local_dir = plugins_dir })
