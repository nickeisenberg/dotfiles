return {
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          markdown = { "prettier" },
        }
      })
    end,
  },
  {
    'mason-org/mason.nvim',
    version = "1.11.0",
    enabled = true,
    dependencies = {
      'neovim/nvim-lspconfig',
      'hrsh7th/cmp-nvim-lsp',
      { 'mason-org/mason-lspconfig.nvim', version = "1.32.0" }
    },
    config = function()
      local on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(
          bufnr,
          'Format',
          function(_)
            if client.name == "ruff" then
              vim.lsp.buf.code_action {
                context = {
                  only = { 'source.fixAll.ruff' }
                },
                apply = true,
              }
            end
            if vim.bo.filetype ~= "markdown" then
              vim.lsp.buf.format()
            end
            require("conform").format()
          end,
          { desc = 'Format current buffer with LSP' }
        )

        vim.keymap.set(
          'n', '<leader>rn', vim.lsp.buf.rename, { desc = 'LSP: Rename symbol' }
        )

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
}
