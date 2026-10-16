return {
  dir = "rich-md-view.nvim",
  config = function()
    require("rich-md-view").setup({
      -- Fixed interpreter, independent of the active venv.
      python = vim.fn.expand("~/.sysvenv/venv/bin/python"),
    })
  end,
}
