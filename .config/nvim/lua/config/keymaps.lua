vim.keymap.set("n", "<leader>ve", vim.cmd.Ex)
vim.keymap.set("n", "<S-h>", vim.cmd.BufferLineCyclePrev)
vim.keymap.set("n", "<S-l>", vim.cmd.BufferLineCycleNext)
vim.keymap.set("n", "<leader>bd", vim.cmd.bd)
vim.cmd([[nnoremap <leader>md `>]])
vim.cmd([[nnoremap <leader>mu `<]])

-- line and column highlight
vim.cmd([[map <leader>lc :set cursorcolumn!<Bar>set cursorline!<CR>]])
