-- close a buffer
vim.keymap.set("n", "<leader>bd", vim.cmd.bd)

-- Move to the bottom or top of the previous highlihgt
vim.cmd([[nnoremap <leader>md `>]])
vim.cmd([[nnoremap <leader>mu `<]])

-- Copy to clipboard
vim.cmd([[vnoremap  <leader>y  "+y]])
vim.cmd([[nnoremap  <leader>y  "+y]])

-- Paste from clipboard
vim.cmd([[nnoremap <leader>p "+p]])
vim.cmd([[nnoremap <leader>P "+P]])
vim.cmd([[vnoremap <leader>p "+p]])
vim.cmd([[vnoremap <leader>P "+P]])

-- Move to the next paragraph without opening folds
vim.api.nvim_set_keymap(
  'n', '}', [[<Cmd>execute foldclosed('.') == -1 ? "normal! }" : "normal! j"<CR>]],
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  'v', '}', [[<Cmd>execute foldclosed('.') == -1 ? "normal! }" : "normal! j"<CR>]],
  { noremap = true, silent = true }
)

-- Move to the previous paragraph without opening folds
vim.api.nvim_set_keymap(
  'n', '{', [[<Cmd>execute foldclosed('.') == -1 ? "normal! {" : "normal! k"<CR>]],
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  'v', '{', [[<Cmd>execute foldclosed('.') == -1 ? "normal! {" : "normal! k"<CR>]],
  { noremap = true, silent = true }
)

-- Easier save key
vim.keymap.set("n", "<leader>w", "<ESC>:w <CR>")

-- splits
vim.keymap.set("n", "<leader>vs", ":vsplit <CR>")
vim.keymap.set("n", "<leader>ss", ":split <CR>")
vim.keymap.set("n", "<leader>cs", ":close <CR>")

-- navigate splits
vim.keymap.set("n", "<leader>l", ":wincmd l <CR>")
vim.keymap.set("n", "<leader>h", ":wincmd h <CR>")
vim.keymap.set("n", "<leader>j", ":wincmd j <CR>")
vim.keymap.set("n", "<leader>k", ":wincmd k <CR>")

--  Fugitive keymap
vim.keymap.set("n", "<leader>vf", ":G ")

-- Resize splits
vim.keymap.set("n","<c-Up>", ":resize -2 <cr>")
vim.keymap.set("n","<c-Down>", ":resize +2 <cr>")
vim.keymap.set("n","<c-Left>", ":vertical resize -2 <cr>")
vim.keymap.set("n","<c-Right>", ":vertical resize +2 <cr>")
