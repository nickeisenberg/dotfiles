return {
  'mason-org/mason.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'mason-org/mason-lspconfig.nvim',
    'stevearc/conform.nvim',
    'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require('mason-lspconfig')
    local conform = require("conform")

    local servers = {
      clangd = {},
      pyright = {},
      ruff = {},
      bashls = { filetypes = { "sh", "zsh" } },
      sqlls = {},
      texlab = {},
      vimls = {},
      marksman = {},
      html = { filetypes = { 'html', 'twig', 'hbs', 'htmldjango' } },
      lua_ls = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    }

    local server_names = {}
    for name, _ in pairs(servers) do
      table.insert(server_names, name)
    end

    mason.setup()
    mason_lspconfig.setup({
      ensure_installed = server_names
    })

    conform.setup({
      log_level = vim.log.levels.DEBUG,
      formatters_by_ft = {
        markdown = { "prettier", "mdformat" },
      }
    })

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
          conform.format()
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
    
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    for server_name, server_config in pairs(servers) do
      vim.lsp.config(server_name, {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = server_config,
        filetypes = (server_config or {}).filetypes,
      })
    end
  end
}
