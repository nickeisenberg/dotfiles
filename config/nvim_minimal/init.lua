vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load configuration.
require("core")
require("ui")
require("coding")
require("utils")

-- Load plugins: every file in lua/plugins/ returns a spec for pack.nvim.
vim.opt.runtimepath:prepend(vim.fn.stdpath("config") .. "/plugins/pack.nvim")
require("pack").setup()
