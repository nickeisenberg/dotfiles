return {
  'lervag/vimtex',
  lazy = false,
  init = function ()
    local os_name = require("utils").get_os_name
    if os_name() == "Darwin" then
      vim.cmd(
        [[let g:vimtex_view_method = 'skim']]
      )
    else
      vim.cmd(
        [[let g:vimtex_view_method = 'zathura']]
      )
      -- vim.cmd(
      --   [[let g:vimtex_view_general_viewer = 'google-chrome']]
      -- )
    end
  end
}
