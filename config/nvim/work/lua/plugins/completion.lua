return {
  dir = "completion.nvim",
  config = function()
    require("completion").setup({
      sources = { "path", "snippets", "lsp", "buffer" },
      snippets = {
        paths = {
          -- Your own: <filetype>.json and all.json.
          vim.fn.stdpath("config") .. "/snippets",
          -- A VSCode snippet extension such as friendly-snippets, if you
          -- add it to a spec; a missing directory is skipped.
          vim.fn.stdpath("data") .. "/site/pack/core/opt/friendly-snippets",
        },
      },
      signature = { border = "rounded" },
    })
  end,
}
