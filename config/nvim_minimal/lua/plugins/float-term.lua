local term = require("float-term")

vim.keymap.set("n", "<leader>tt", term.toggle, {
  desc = "Terminal: Toggle",
})

vim.keymap.set("n", "<leader>tn", term.new, {
  desc = "Terminal: New",
})

vim.keymap.set("n", "<leader>th", term.prev, {
  desc = "Terminal: Previous",
})

vim.keymap.set("n", "<leader>tl", term.next, {
  desc = "Terminal: Next",
})

vim.keymap.set("n", "<leader>tk", term.kill, {
  desc = "Terminal: Kill",
})
