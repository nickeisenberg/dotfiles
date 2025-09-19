vim.lsp.config('pyright', {
  capabilities = require('cmp_nvim_lsp').default_capabilities()
})

vim.lsp.enable("pyright")
