return {
  "voldikss/vim-floaterm",
  config = function ()
    vim.cmd([[nnoremap <leader>tt :FloatermToggle<CR>]])
    vim.cmd([[tnoremap <leader>tt <C-\><C-n>:FloatermToggle<CR>]])
    vim.cmd([[let g:floaterm_shell="/usr/bin/bash --login"]])
    vim.cmd([[let g:floaterm_width=0.8]])
    vim.cmd([[let g:floaterm_height=0.8]])
  end
}
