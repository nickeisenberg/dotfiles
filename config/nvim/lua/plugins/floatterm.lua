return {
  "voldikss/vim-floaterm",
  enabled = true,
  config = function ()
    vim.cmd([[nnoremap <leader>tt :FloatermToggle<CR>]])
    vim.cmd([[tnoremap <leader>tt <C-\><C-n>:FloatermToggle<CR>]])
    vim.cmd([[nnoremap <leader>tn :FloatermNew<CR>]])
    vim.cmd([[tnoremap <leader>tn <C-\><C-n>:FloatermNew<CR>]])
    vim.cmd([[nnoremap <leader>tl :FloatermNext<CR>]])
    vim.cmd([[tnoremap <leader>tl <C-\><C-n>:FloatermNext<CR>]])
    vim.cmd([[nnoremap <leader>th :FloatermPrev<CR>]])
    vim.cmd([[tnoremap <leader>th <C-\><C-n>:FloatermPrev<CR>]])
    vim.cmd([[nnoremap <leader>tk :FloatermKill<CR>]])
    vim.cmd([[tnoremap <leader>tk <C-\><C-n>:FloatermKill<CR>]])
    vim.cmd([[let g:floaterm_shell= &shell . " --login"]])
    vim.cmd([[let g:floaterm_width=0.8]])
    vim.cmd([[let g:floaterm_height=0.8]])
    vim.cmd([[let g:floaterm_title="ft:$1/$2"]])
  end
}
