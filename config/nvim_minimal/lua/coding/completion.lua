vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if not client then
      return
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, {
        autotrigger = true,
      })

      vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = ev.buf,
        callback = function()
          if vim.fn.pumvisible() == 1 then
            return
          end

          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local before = line:sub(1, col)

          if before:match("[%w_][%w_]$") then
            vim.lsp.completion.get()
          end
        end,
      })
    end

    if client:supports_method("textDocument/signatureHelp") then
      vim.api.nvim_create_autocmd("InsertCharPre", {
        buffer = ev.buf,
        callback = function()
          if vim.v.char == "(" or vim.v.char == "," then
            vim.schedule(function()
              vim.lsp.buf.signature_help({
                border = "rounded",
              })
            end)
          end
        end,
      })
    end
  end,
})

vim.opt.completeopt = {
  "menu",
  "menuone",
  "noselect",
}
