vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if not client then
      return
    end

    -- Native LSP completion
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, {
        autotrigger = true,
      })

      -- Trigger completion while typing normal identifiers.
      --
      -- Only request new completions when the popup isn't already
      -- visible. When it is visible, let Neovim filter the existing
      -- completion results.
      vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = ev.buf,
        callback = function()
          if vim.fn.pumvisible() == 1 then
            return
          end

          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local before = line:sub(1, col)

          -- Trigger after at least two identifier characters.
          if before:match("[%w_][%w_]$") then
            vim.lsp.completion.get()
          end
        end,
      })
    end

    -- Signature help
    --
    -- Automatically show function arguments after "(" and update
    -- the signature when moving to the next argument with ",".
    if client:supports_method("textDocument/signatureHelp") then
      vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, {
        buffer = ev.buf,
        desc = "Signature help",
      })

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

    -- LSP navigation
    local opts = { buffer = ev.buf }

    -- Go to definition
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

    -- Find references
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

    -- Hover documentation
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

    -- Rename symbol
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

    -- Code actions
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})

-- Completion menu behavior.
--
-- Keep the menu open while typing, but don't automatically select
-- a completion candidate.
vim.opt.completeopt = {
  "menu",
  "menuone",
  "noselect",
}
