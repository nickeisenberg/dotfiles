return {
  dir = "rich-md-view.nvim",
  build = function(plugin)
    require("rich-md-view.build").run(plugin)
  end,
  config = function()
    require("rich-md-view").setup()

    vim.keymap.set("n", "<leader>rt", require("rich-md-view").toggle)
  end,
}
