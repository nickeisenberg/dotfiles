let mapleader = " "

colorscheme habamax

set foldmethod=indent
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set mouse=a
set number

"--------------------------------------------------
" splits
"--------------------------------------------------
nnoremap <Leader>cs :close<CR>
nnoremap <Leader>h <C-w>h
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k
nnoremap <Leader>l <C-w>l
nnoremap <Leader>sv :vsplit<CR>
nnoremap <Leader>sh :split<CR>
"--------------------------------------------------

nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>p "+p
vnoremap <leader>p "+p

nnoremap <leader>w :w<CR>

"--------------------------------------------------
" slime
"--------------------------------------------------
let g:slime_target = "vimterminal"

function! ToggleTerminal(split_type)
  " Find an existing terminal buffer
  let term_buf = -1
  for buf in range(1, bufnr('$'))
    if getbufvar(buf, '&buftype') ==# 'terminal'
      let term_buf = buf
      break
    endif
  endfor

  if term_buf > 0
    " Check if the terminal is open in any window
    let win_id = bufwinnr(term_buf)
    if win_id > 0
      " Close the terminal if it's visible
      execute win_id . "wincmd c"
    else
      " If terminal exists but is hidden, open it in specified split type
      if a:split_type ==# 'vertical'
        execute "vert botright sbuffer " . term_buf
      else
        execute "botright sbuffer " . term_buf
      endif
    endif
  else
    " No terminal exists, open a new one in specified split type
    if a:split_type ==# 'vertical'
      execute "vert botright term"
    else
      execute "botright term"
    endif
    setlocal bufhidden=hide
  endif
endfunction

" Key mappings
nnoremap <Leader>rv :call ToggleTerminal('vertical')<CR>
nnoremap <Leader>rh :call ToggleTerminal('horizontal')<CR>
"--------------------------------------------------


call plug#begin('~/.vim/plugged')

Plug 'jpalardy/vim-slime'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()
