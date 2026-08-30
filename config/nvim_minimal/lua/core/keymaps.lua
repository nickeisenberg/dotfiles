-- Close buffer
vim.keymap.set("n", "<leader>bd", vim.cmd.bd)

-- Surround selection with quotes
vim.keymap.set("v", '<leader>"', 'c""<Esc>P', {
  silent = true,
})

-- Move to previous visual selection
vim.keymap.set("n", "<leader>md", "`>")
vim.keymap.set("n", "<leader>mu", "`<")

-- System clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y')
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p')
vim.keymap.set({ "n", "v" }, "<leader>P", '"+P')

-- Diagnostics
vim.keymap.set("n", "<leader>id", vim.diagnostic.open_float)

-- Move between paragraphs without opening folds
vim.keymap.set({ "n", "v" }, "}", function()
  if vim.fn.foldclosed(".") == -1 then
    vim.cmd.normal({ "}", bang = true })
  else
    vim.cmd.normal({ "j", bang = true })
  end
end)

vim.keymap.set({ "n", "v" }, "{", function()
  if vim.fn.foldclosed(".") == -1 then
    vim.cmd.normal({ "{", bang = true })
  else
    vim.cmd.normal({ "k", bang = true })
  end
end)

-- File explorer
vim.keymap.set("n", "<leader>O", vim.cmd.Ex)

-- Save and quit
vim.keymap.set("n", "<leader>w", vim.cmd.write)
vim.keymap.set("n", "<leader>q", vim.cmd.quit)
vim.keymap.set("n", "<leader>Q", function()
  vim.cmd.quit({ bang = true })
end)

-- Splits
vim.keymap.set("n", "<leader>sv", vim.cmd.vsplit)
vim.keymap.set("n", "<leader>sh", vim.cmd.split)
vim.keymap.set("n", "<leader>cs", vim.cmd.close)

-- Fugitive
vim.keymap.set("n", "<leader>vf", ":G ")

-- Resize splits
vim.keymap.set("n", "<C-Up>", "<Cmd>resize -2<CR>")
vim.keymap.set("n", "<C-Down>", "<Cmd>resize +2<CR>")
vim.keymap.set("n", "<C-Left>", "<Cmd>vertical resize -2<CR>")
vim.keymap.set("n", "<C-Right>", "<Cmd>vertical resize +2<CR>")
