return {
  'lervag/vimtex',
  lazy = false,
  init = function ()
    vim.cmd([[let g:vimtex_view_method = 'zathura']])
  end
}
