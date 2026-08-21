local picker = require("picker")

-- General pickers

vim.keymap.set("n", "<leader>ff", picker.find_files, {
  desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", picker.live_grep, {
  desc = "Live grep",
})

vim.keymap.set("n", "<leader>fb", picker.find_buffers, {
  desc = "Find buffers",
})

-- LSP pickers

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.keymap.set("n", "<leader>gr", picker.references, {
      buffer = ev.buf,
      desc = "LSP: References",
    })
  end,
})
