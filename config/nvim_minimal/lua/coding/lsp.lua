vim.lsp.enable({
  "lua_ls",
  "pyright",
  "tsgo",
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = ev.buf,
        desc = desc,
      })
    end

    -- Native LSP actions that don't need a picker.
    map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: Code action")
    map("i", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature help")
  end,
})
