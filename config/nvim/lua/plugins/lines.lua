return {
  {
    'lukas-reineke/indent-blankline.nvim',
    enabled=true,
    main = 'ibl',
    opts = {},
    config = function ()
      require("ibl").setup {
        scope = {
          enabled = false
        },
        indent = {
          char = "┊"
        },
      }
    end
  },

  {
    "lukas-reineke/virt-column.nvim",
    enabled = true,
    config = function ()
      require("virt-column").setup({
        char = "┊"
      })
      vim.o.colorcolumn = "80"
    end
  }
}
