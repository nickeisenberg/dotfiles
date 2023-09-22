vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = {
    colorscheme = { "tokyonight" }
  },
})

require('config')

vim.cmd(
  [[
    let g:LanguageClient_serverCommands = {
      \ 'sql': ['sql-language-server', 'up', '--method', 'stdio'],
      \ }
  ]]
)
