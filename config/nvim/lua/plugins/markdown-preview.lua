local without_yarn = {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function() vim.fn["mkdp#util#install"]() end,
}

-- install yarn with `npm install -g yarn`
local with_yarn = {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    vim.g.mkdp_echo_preview_url = 1  -- prints the full URL in :messages
    vim.g.mkdp_port = '9001'
  end,
  ft = { "markdown" },
}

return with_yarn
