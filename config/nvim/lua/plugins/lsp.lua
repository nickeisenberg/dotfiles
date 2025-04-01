return {
  'williamboman/mason.nvim',
  enabled = true,
  dependencies = {
    'neovim/nvim-lspconfig',
    'williamboman/mason-lspconfig.nvim',
  },
  config = function()
    local on_attach = function(client, bufnr)
      if client.name == "ruff" then
        vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
          vim.lsp.buf.code_action {
            context = {
              only = { 'source.fixAll.ruff' }
            },
            apply = true,
          }
          vim.lsp.buf.format()
        end, { desc = "Ruff: Apply all autofixable fixes" })
      else
        vim.api.nvim_buf_create_user_command(
          bufnr,
          'Format',
          function(_)
            vim.lsp.buf.format()
          end,
          { desc = 'Format current buffer with LSP' }
        )
      end

      vim.keymap.set(
        'n', '<leader>gd', require('telescope.builtin').lsp_definitions,
        { buffer = bufnr, desc = '[G]oto [D]efinition' }
      )

      vim.keymap.set(
        'n', '<leader>gr', require('telescope.builtin').lsp_references,
        { buffer = bufnr, desc = '[G]oto [D]efinition' }
      )

      vim.keymap.set(
        'n', '<leader>gs', require('telescope.builtin').lsp_document_symbols,
        { buffer = bufnr, desc = '[D]ocument [S]ymbols' }
      )
    end

    local mason = require("mason")
    local mason_lspconfig = require('mason-lspconfig')
    local lspconfig = require("lspconfig")

    mason.setup()
    mason_lspconfig.setup()

    local servers = {
      clangd = {},
      pyright = {},
      ruff = {},
      bashls = { filetypes = { "sh", "zsh" } },
      sqlls = {},
      texlab = {},
      marksman = {},
      html = { filetypes = { 'html', 'twig', 'hbs', 'htmldjango' } },
      lua_ls = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    }

    local capabilities = require('cmp_nvim_lsp').default_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    )

    mason_lspconfig.setup({
      ensure_installed = vim.tbl_keys(servers),
    })

    mason_lspconfig.setup_handlers {
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          settings = servers[server_name],
          filetypes = (servers[server_name] or {}).filetypes,
        })
      end,
    }
  end
}
