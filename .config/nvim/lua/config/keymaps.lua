-- vim built in file explorer
-- vim.keymap.set("n", "<leader>ve", vim.cmd.Ex)
vim.keymap.set(
  "n",
  "<leader>ve",
  function()
    vim.cmd.tabnew()
    vim.cmd.Ex()
  end
)

-- Move the the previous or next buffer
vim.keymap.set("n", "<S-h>", vim.cmd.BufferLineCyclePrev)
vim.keymap.set("n", "<S-l>", vim.cmd.BufferLineCycleNext)

-- close a buffer
vim.keymap.set("n", "<leader>bd", vim.cmd.bd)

-- Move to the bottom or top of the previous highlihgt
vim.cmd([[nnoremap <leader>md `>]])
vim.cmd([[nnoremap <leader>mu `<]])

-- line and column highlight
vim.cmd([[map <leader>lc :set cursorcolumn!<Bar>set cursorline!<CR>]])

-- Copy to clipboard
vim.cmd([[vnoremap  <leader>y  "+y]])
-- vim.cmd([[nnoremap  <leader>Y  "+yg_]])
vim.cmd([[nnoremap  <leader>y  "+y]])
-- vim.cmd([[nnoremap  <leader>yy  "+yy]])

-- Paste from clipboard
vim.cmd([[nnoremap <leader>p "+p]])
vim.cmd([[nnoremap <leader>P "+P]])
vim.cmd([[vnoremap <leader>p "+p]])
vim.cmd([[vnoremap <leader>P "+P]])

-- navigate splits
vim.keymap.set("n", "<leader>l", ":wincmd l <CR>")
vim.keymap.set("n", "<leader>h", ":wincmd h <CR>")
vim.keymap.set("n", "<leader>j", ":wincmd j <CR>")
vim.keymap.set("n", "<leader>k", ":wincmd k <CR>")
