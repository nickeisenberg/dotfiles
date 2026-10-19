return {
  dir = "statusline.nvim",
  config = function()
    require("statusline").setup({
      show = {
        mode = true,
        git = true,
        diff = true,
        diagnostics = true,
        lsp = true,
        filetype = true,
        position = true,
      },
    })
  end,
}
