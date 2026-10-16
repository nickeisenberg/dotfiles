return {
  dir = "rich-md-view.nvim",
  -- A function, because the plugin isn't on 'runtimepath' yet when this
  -- file is read.
  build = function(plugin)
    require("rich-md-view.build").run(plugin)
  end,
  config = function()
    require("rich-md-view").setup()
  end,
}
