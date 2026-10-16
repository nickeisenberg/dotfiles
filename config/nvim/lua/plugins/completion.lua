return {
  dir = "completion.nvim",
  deps = { "rafamadriz/friendly-snippets" },
  config = function()
    require("completion").setup({
      sources = { "path", "snippets", "lsp", "buffer" },
      snippets = {
        paths = {
          -- Your own: <filetype>.json and all.json.
          vim.fn.stdpath("config") .. "/snippets",
          -- friendly-snippets, installed by pack.nvim.
          vim.fn.stdpath("data") .. "/site/pack/core/opt/friendly-snippets",
        },
      },
      signature = { border = "rounded" },
    })
  end,
}
