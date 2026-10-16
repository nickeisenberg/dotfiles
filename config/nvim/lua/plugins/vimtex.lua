return {
  "lervag/vimtex",
  config = function()
    if vim.uv.os_uname().sysname == "Darwin" then
      vim.cmd([[let g:vimtex_view_method = 'skim']])
    else
      vim.g.vimtex_view_method = "zathura"
      -- vim.cmd(
      --   [[let g:vimtex_view_general_viewer = 'google-chrome']]
      -- )
    end
  end,
}
