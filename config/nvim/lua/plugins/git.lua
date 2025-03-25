return {
  {
    "junegunn/gv.vim",
    dependencies = { "tpope/vim-fugitive" }
  },

  {
    'lewis6991/gitsigns.nvim',
    requires = {
      'nvim-lua/plenary.nvim'
    },
    config = function()
      require('gitsigns').setup()
    end
  }
}
