return {
  dir = "mark-tui.nvim",
  config = function()
    require("mark-tui").setup({
      -- Fixed interpreter, independent of the active venv.
      python = vim.fn.expand("~/.sysvenv/venv/bin/python"),
    })
  end,
}
