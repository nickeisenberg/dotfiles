return {
  dir = "completion.nvim",
  config = function()
    require("completion").setup({
      sources = { "path", "snippets", "lsp", "buffer" },
      signature = { border = "rounded" },
    })
  end,
}
