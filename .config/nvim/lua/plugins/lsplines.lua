return {
  "ErichDonGubler/lsp_lines.nvim",
  enabled = false,
  config = function ()
    local lsplines = require("lsp_lines")
    lsplines.setup()
    vim.diagnostic.config({ virtual_text = false })
    vim.keymap.set("n", "<leader>id", require("lsp_lines").toggle, { desc = "Inline Diagnostics" })
  end
}
