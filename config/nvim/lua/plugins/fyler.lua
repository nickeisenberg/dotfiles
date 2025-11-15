return {
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-mini/mini.icons" },
  branch = "stable",
  opts = {},
  config = function (_, opts)
    local fyler = require("fyler")
    fyler.setup(opts)
    vim.keymap.set("n", "<space>O", "<cmd>Fyler<cr>")
  end
}
