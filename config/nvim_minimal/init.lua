vim.g.mapleader = " "

-- Add locally developed plugins.
local plugin_root = vim.fn.stdpath("config") .. "/plugins"
vim.opt.runtimepath:prepend(plugin_root .. "/picker.nvim")

-- Load configuration.
require("core")
require("ui")
require("coding")
require("plugins")
