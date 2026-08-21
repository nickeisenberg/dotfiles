local picker = require("picker")

vim.keymap.set("n", "<leader>ff", picker.find_files, {
  desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", picker.live_grep, {
  desc = "Live grep",
})

vim.keymap.set("n", "<leader>fb", picker.find_buffers, {
  desc = "Find buffers",
})
