return {
  dir = "rich-md-view.nvim",
  build = function(plugin)
    require("rich-md-view.build").run(plugin)
  end,
  config = function()
    require("rich-md-view").setup()
  end,
}
