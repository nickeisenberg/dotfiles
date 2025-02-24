let mapleader = ' '


" vague.nvim background color
"--------------------------------------------------
colorscheme habamax
autocmd VimEnter * highlight Normal ctermbg=NONE guibg=#141415

" settings and maps
"--------------------------------------------------
set tabstop=4
set shiftwidth=4
set expandtab
set foldmethod=indent
set autoindent
set mouse=a
set number
set updatetime=100

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

" plugins
"--------------------------------------------------
call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'rafamadriz/friendly-snippets'
Plug 'jpalardy/vim-slime'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'mhinz/vim-signify'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'voldikss/vim-floaterm'
Plug 'preservim/nerdtree'

call plug#end()

" plugin configs
"--------------------------------------------------

" NERDTree
"--------------------------------------------------
nnoremap <Leader>O :NERDTreeToggle<CR>

" slime iron.nvim emulator
"--------------------------------------------------
let g:slime_target = "vimterminal"

if !empty($VIRTUAL_ENV)
  let python_def = "source $VIRTUAL_ENV/bin/activate && clear && which python3 && python3" 
else
  let python_def = "python3" 
endif

let g:slime_extras_repl_def = {
  \ 'sh': 'bash -l',
  \ 'vim': 'bash -l',
  \ 'python': python_def,
\}

let g:slime_extras_repl_open_cmd = {
  \ 'vertical': 'vert botright',
  \ 'horizontal': 'rightbelow',
\}

let g:slime_extras_repl_size = {
  \ 'vertical': 0.4,
  \ 'horizontal': 0.25,
\}

function! ToggleRepl(split_type)
  " helper function
  function! s:ConfigureSplit(split_type)
    if a:split_type ==# 'vertical'
      let g:_term_open_cmd = g:slime_extras_repl_open_cmd["vertical"]
      let _term_size = float2nr(winwidth(0) * g:slime_extras_repl_size["vertical"])
      let g:_term_size = "vertical resize " . _term_size

    elseif a:split_type ==# 'horizontal'
      let g:_term_open_cmd = g:slime_extras_repl_open_cmd["horizontal"]
      let _term_size = float2nr(winheight(0) * g:slime_extras_repl_size["horizontal"])
      let g:_term_size =  "resize " . _term_size
    endif
  endfunction

  if !exists("g:_repl_bufs")
    let g:_repl_bufs = []
  endif

  " Initial values
  if !exists("g:_term_open_cmd")
    call s:ConfigureSplit("vertical")
  endif

  let g:_repl_buf = -1
  for buf in g:_repl_bufs
    if bufexists(buf) && getbufvar(buf, '&buftype') ==# 'terminal'
      let g:_repl_buf = buf
      break
    endif
  endfor

  let current_win_id = win_getid()
  let ft = &filetype

  if g:_repl_buf > 0
    let win_id = bufwinnr(g:_repl_buf)
    if win_id > 0
      execute win_id . "wincmd c"

    else
      call s:ConfigureSplit(a:split_type)
      execute g:_term_open_cmd . " sbuffer " . g:_repl_buf
      execute g:_term_size
      call win_gotoid(current_win_id)
    endif

  else
    call s:ConfigureSplit(a:split_type)
    execute g:_term_open_cmd . " term ++shell=" . shellescape(&shell)
    execute g:_term_size
    let g:_repl_buf = bufnr('$')
    call add(g:_repl_bufs, g:_repl_buf)

    if has_key(g:slime_extras_repl_def, ft)
      call term_sendkeys(g:_repl_buf, g:slime_extras_repl_def[ft] . "\n")
    else
      call term_sendkeys(g:_repl_buf, ft . "\n")
    endif

    setlocal bufhidden=hide

    " kills terminal on :q so this does not need to be done manually
    autocmd QuitPre * execute ':bd! ' . g:_repl_buf

    call win_gotoid(current_win_id)
  endif
endfunction

 
nnoremap <Leader>rr :call ToggleRepl('toggle')<CR>

nnoremap <Leader>rv :call ToggleRepl('vertical')<CR>
nnoremap <Leader>rh :call ToggleRepl('horizontal')<CR>

nnoremap <leader>sl :SlimeSendCurrentLine<CR>
nnoremap <leader>sp <Plug>SlimeParagraphSend<CR>
vnoremap <leader>sp <Plug>SlimeRegionSend<CR>

" vim-floaterm
"--------------------------------------------------
nnoremap <Leader>tt :FloatermToggle<CR>
nnoremap <Leader>tk :FloatermKill<CR>

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
