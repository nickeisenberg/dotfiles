return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  commit = "3d08501caef2329aba5121b753e903904088f7e6",
  opts = {},
  config = function ()
    require("ibl").setup {
       scope = {
        show_exact_scope = false
      }
    }
  end
}
