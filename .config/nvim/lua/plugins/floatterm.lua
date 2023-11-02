return {
  "voldikss/vim-floaterm",
  config = function ()
    vim.cmd([[nnoremap <leader>tt :FloatermToggle<CR>]])
    vim.cmd([[tnoremap <leader>tt <C-\><C-n>:FloatermToggle<CR>]])
    vim.cmd([[nnoremap <leader>tm :FloatermNew<CR>]])
    vim.cmd([[tnoremap <leader>tm <C-\><C-n>:FloatermNew<CR>]])
    vim.cmd([[nnoremap <leader>tn :FloatermNext<CR>]])
    vim.cmd([[tnoremap <leader>tn <C-\><C-n>:FloatermNext<CR>]])
    vim.cmd([[nnoremap <leader>tp :FloatermPrev<CR>]])
    vim.cmd([[tnoremap <leader>tp <C-\><C-n>:FloatermPrev<CR>]])
    vim.cmd([[nnoremap <leader>tk :FloatermKill<CR>]])
    vim.cmd([[tnoremap <leader>tk <C-\><C-n>:FloatermKill<CR>]])
    vim.cmd([[let g:floaterm_shell="/usr/bin/bash --login"]])
    vim.cmd([[let g:floaterm_width=0.8]])
    vim.cmd([[let g:floaterm_height=0.8]])
    vim.cmd([[let g:floaterm_title="ft:$1/$2"]])
  end
}
