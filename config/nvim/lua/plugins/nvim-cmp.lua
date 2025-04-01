return {
  -- Autocompletion 
  'hrsh7th/nvim-cmp',
  commit = "1e1900b0769324a9675ef85b38f99cca29e203b3",
  enabled = true,
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'rafamadriz/friendly-snippets',
      'hrsh7th/cmp-cmdline',
    {
      'hrsh7th/cmp-nvim-lsp',
      commit = "99290b3ec1322070bcfb9e846450a46f6efa50f0"
    },
    {
      'hrsh7th/cmp-path',
      commit = "91ff86cd9c29299a64f968ebb45846c485725f23"
    },
  },
  config = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')

    require('luasnip.loaders.from_vscode').lazy_load()

    luasnip.config.setup({})

    luasnip.filetype_extend("htmldjango", {"html"})

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete {},
        ['<C-y>'] = cmp.mapping.confirm {
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        },
      },
      sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' },
      },
    })

    cmp.setup.cmdline(
      ':',
      {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources(
          { { name = 'path' } },
          {
            {
              name = 'cmdline',
              option = { ignore_cmds = { 'Man', '!' } }
            }
          }
        )
      }
    )
  end
}
