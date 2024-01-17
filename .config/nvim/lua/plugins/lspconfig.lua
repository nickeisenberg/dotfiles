return {
  'neovim/nvim-lspconfig',
  enabled = true,
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',

    -- Useful status updates for LSP
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

    -- Additional lua configuration, makes nvim stuff amazing!
    'folke/neodev.nvim',
  },
  config = function ()
    local on_attach = function(_, bufnr)

      local nmap = function(keys, func, desc)
        if desc then
          desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
      end

      nmap('<leader>gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
      nmap('<leader>gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
      nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
      nmap('K', vim.lsp.buf.hover, 'Hover Documentation')

      -- Create a command `:Format` local to the LSP buffer
      vim.api.nvim_buf_create_user_command(
        bufnr,
        'Format',
        function(_)
          vim.lsp.buf.format()
        end,
        { desc = 'Format current buffer with LSP' }
      )
    end

    require('mason').setup()
    require('mason-lspconfig').setup()

    local servers = {
      clangd = {},
      pyright = {},
      rust_analyzer = {},
      bashls = {},
      sqlls = {},
      texlab = {},
      tsserver = {},
      marksman = {},
      html = { filetypes = { 'html', 'twig', 'hbs', 'htmldjango' } },
      lua_ls = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    }

    require('neodev').setup()

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    local mason_lspconfig = require 'mason-lspconfig'

    mason_lspconfig.setup {
      ensure_installed = vim.tbl_keys(servers),
    }

    mason_lspconfig.setup_handlers {
      function(server_name)
        require('lspconfig')[server_name].setup {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = servers[server_name],
          filetypes = (servers[server_name] or {}).filetypes,
        }
      end,
    }

  end
}
