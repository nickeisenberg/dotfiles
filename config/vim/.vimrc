let mapleader = ' '

" settings and maps
"--------------------------------------------------
set tabstop=4
set shiftwidth=4
set foldmethod=indent
set autoindent
set mouse=a
set number
set updatetime=100
set colorcolumn=80
set wrap

" move to the next/prev paragraph without opening folds
"--------------------------------------------------
nnoremap <expr> } foldclosed('.') == -1 ? '}' : 'j'
vnoremap <expr> } foldclosed('.') == -1 ? '}' : 'j'
nnoremap <expr> { foldclosed('.') == -1 ? '{' : 'k'
vnoremap <expr> { foldclosed('.') == -1 ? '{' : 'k'

" splits
"--------------------------------------------------
nnoremap <Leader>cs :close<CR>
nnoremap <Leader>h <C-w>h
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k
nnoremap <Leader>l <C-w>l
nnoremap <Leader>sv :vsplit<CR>
nnoremap <Leader>sh :split<CR>

" easy clipboard
"--------------------------------------------------
nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>p "+p
vnoremap <leader>p "+p

" quick write 
"--------------------------------------------------
nnoremap <leader>w :w<CR>

" quick floaterm
"--------------------------------------------------
let g:float_term_win_id = -1
let g:float_term_current_buf_idx = -1
let g:float_term_buf_ids = []

function! NewFloatTerminal()
  if g:float_term_win_id != -1
    call popup_close(g:float_term_win_id)
    let g:float_term_win_id = -1
  endif

  let new_buf_id = term_start(&shell . " -l", {'hidden': 1})
  call add(g:float_term_buf_ids, new_buf_id)

  let g:float_term_current_buf_idx = len(g:float_term_buf_ids) - 1

  if exists('$VIRTUAL_ENV') && !empty($VIRTUAL_ENV)
    call term_sendkeys(
      \ g:float_term_buf_ids[-1], 
      \ "source " . $VIRTUAL_ENV . "/bin/activate && clear" . "\n"
    \)
  endif

  let width = float2nr(&columns * 0.75)
  let height = float2nr(&lines * 0.75)
  let row = (&lines - height) / 2
  let col = (&columns - width) / 2
  
  let g:float_term_win_id = popup_create(g:float_term_buf_ids[-1], {
    \ 'line': row,
    \ 'col': col,
    \ 'title': (g:float_term_current_buf_idx + 1) . "/" . len(g:float_term_buf_ids),
    \ 'minwidth': width,
    \ 'minheight': height,
    \ 'border': [],
    \ 'wrap': 0,
    \ 'mapping': 0
    \ })
endfunction

function! ToggleFloatTerminal()
  if g:float_term_win_id != -1
    call popup_close(g:float_term_win_id)
    let g:float_term_win_id = -1
    return
  endif

  if len(g:float_term_buf_ids) == 0
    call NewFloatTerminal()
    return
  endif

  let width = float2nr(&columns * 0.75)
  let height = float2nr(&lines * 0.75)
  let row = (&lines - height) / 2
  let col = (&columns - width) / 2

  let g:float_term_win_id = popup_create(g:float_term_buf_ids[g:float_term_current_buf_idx], 
    \ {
    \ 'line': row,
    \ 'col': col,
    \ 'title': (g:float_term_current_buf_idx + 1) . "/" . len(g:float_term_buf_ids),
    \ 'minwidth': width,
    \ 'minheight': height,
    \ 'border': [],
    \ 'wrap': 0,
    \ 'mapping': 0
    \ })
endfunction

function! CycleFloatTerminal(direction)
  if len(g:float_term_buf_ids) == 0
    call NewFloatTerminal()
    return
  endif

  if g:float_term_win_id != -1
    call ToggleFloatTerminal()
  endif

  if len(g:float_term_buf_ids) == 1
    call ToggleFloatTerminal()
    return
  endif

  if a:direction == "next"
    let g:float_term_current_buf_idx += 1
  elseif a:direction == "prev"
    let g:float_term_current_buf_idx -= 1
  endif

  let g:float_term_current_buf_idx = g:float_term_current_buf_idx % len(g:float_term_buf_ids)

  call ToggleFloatTerminal()
endfunction

function! KillFloatTerminal(how)
  if len(g:float_term_buf_ids) == 0
    return
  endif

  if g:float_term_win_id != -1
    call ToggleFloatTerminal()
  endif
  
  if a:how == "current"

    let delete_this_buf_id = remove(g:float_term_buf_ids, g:float_term_current_buf_idx)

    if len(g:float_term_buf_ids) == 0
      let g:float_term_current_buf_idx = -1

    else
      if g:float_term_current_buf_idx == len(g:float_term_buf_ids)
        let g:float_term_current_buf_idx -= 1
      endif
    endif

    execute ':bd! ' . delete_this_buf_id

  elseif a:how == "all"
    for idx in range(len(g:float_term_buf_ids))
      execute ':bd! ' . remove(g:float_term_buf_ids, idx)
    endfor
    let g:float_term_current_buf_idx = -1
  endif
endfunction

autocmd ExitPre * call KillFloatTerminal("all")

nnoremap <leader>tt :call ToggleFloatTerminal()<CR>
nnoremap <leader>tn :call NewFloatTerminal()<CR>
nnoremap <leader>th :call CycleFloatTerminal("prev")<CR>
nnoremap <leader>tl :call CycleFloatTerminal("next")<CR>
nnoremap <leader>tk :call KillFloatTerminal("current")<CR>

" plugins
"--------------------------------------------------
set nocompatible

call plug#begin('~/.vim/plugged')
 
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'rafamadriz/friendly-snippets'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'mhinz/vim-signify'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'sheerun/vim-polyglot'
Plug 'rose-pine/vim'

" Plug 'jpalardy/vim-slime'

let iron_dev = 1
if iron_dev == 1
  Plug '~/gitrepos/iron.vim'
else
  Plug 'nickeisenberg/iron.vim'
endif

call plug#end()

" plugin configs
"--------------------------------------------------

" vague.nvim background color
"--------------------------------------------------
set background=dark
colorscheme rosepine
autocmd VimEnter * highlight Normal ctermbg=NONE guibg=#141415

" NERDTree
"--------------------------------------------------
nnoremap <Leader>O :NERDTreeToggle<CR>

" slime iron.nvim emulator (iron.vim)
"--------------------------------------------------
" let g:slime_target = "vimterminal"
" let g:slime_bracketed_paste = 1

" nnoremap <leader>sl :SlimeSend<CR>
" nnoremap <leader>sp <Plug>SlimeParagraphSend<CR>
" vnoremap <leader>sp <Plug>SlimeRegionSend<CR>

" vim-signify
"--------------------------------------------------
nnoremap <Leader>Sd :SignifyDiff<CR>
nnoremap <Leader>Sh :SignifyHunkDiff<CR>

" coc
"--------------------------------------------------
nnoremap K :call CocActionAsync('doHover')<CR>
nnoremap <Leader>gd :call CocAction('jumpDefinition')<CR>
nnoremap <Leader>gr :call CocAction('jumpReferences')<CR>

" fzf
"--------------------------------------------------
nnoremap <Leader>ff :Files<CR>
nnoremap <Leader>fb :Buffers<CR>
nnoremap <Leader>fg :Rg <CR>

" airline
"--------------------------------------------------
let g:airline_powerline_fonts = 1
let g:airline_theme='base16'
let g:airline_section_z = '%p%% %l:%c'
let g:airline#extensions#default#layout = [ ['a', 'b', 'c'], ['x', 'y', 'z'] ]
let g:airline#extensions#branch#enabled = 1
