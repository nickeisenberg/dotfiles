require("oil").setup({
  view_options = {
    show_hidden = true,
  },
  win_options = {
    signcolumn = "yes:2",
  },
})
require("oil-git-status").setup()

vim.keymap.set("n", "<leader>O", "<CMD>Oil<CR>")
