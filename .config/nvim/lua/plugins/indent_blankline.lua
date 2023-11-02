return {
  'lukas-reineke/indent-blankline.nvim',
  config = function ()
    require("ibl").setup {
      indent = {},
      scope = { enabled = false}
    }
  end
}
