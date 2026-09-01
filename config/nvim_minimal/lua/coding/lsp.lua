vim.lsp.enable({
  "lua_ls",
  "pyright",
  "ruff",
  "bashls",
})

vim.opt.updatetime = 250

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

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

    -- Highlight references to the symbol under the cursor.
    if client and client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup(
        "lsp-highlight-" .. ev.buf,
        { clear = true }
      )

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = ev.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = ev.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.g.python_indent = {
  open_paren = "shiftwidth()",
  closed_paren_align_last_line = false,
}
