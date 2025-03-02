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

Plug 'jpalardy/vim-slime'

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
let g:slime_target = "vimterminal"
let g:slime_bracketed_paste = 1

if !empty($VIRTUAL_ENV)
  if trim(system("uname")) == "Linux"
    let python_def = "source $VIRTUAL_ENV/bin/activate && clear && which python3 && python" 
  else
    let python_def = "source $VIRTUAL_ENV/bin/activate && clear && which python3 && ipython --no-autoindent" 
  endif
else
  if trim(system("uname")) == "Linux"
    let python_def = "python" 
  else
    let python_def = "ipython --no-autoindent" 
  endif
endif

let g:iron_repl_def = {
  \ 'sh': 'bash -l',
  \ 'vim': 'bash -l',
  \ 'python': python_def,
\}

let g:iron_repl_open_cmd = {
  \ 'vertical': 'vert botright',
  \ 'horizontal': 'rightbelow',
\}

let g:iron_repl_size = {
  \ 'vertical': 0.4,
  \ 'horizontal': 0.25,
\}

let g:iron_repl_buf_id = -1
let g:iron_repl_split_type = "vertical"

function! IronRepl(split_type)
  if a:split_type != "toggle"
    let g:iron_repl_split_type = a:split_type
  endif

  let g:iron_repl_size_cmd = {
    \ 'vertical': 'vertical resize ' . float2nr(winwidth(0) * g:iron_repl_size["vertical"]),
    \ 'horizontal': 'resize ' . float2nr(winheight(0) * g:iron_repl_size["horizontal"]),
  \}

  let current_win_id = win_getid()
  let ft = &filetype

  if g:iron_repl_buf_id > 0
    let win_id = bufwinnr(g:iron_repl_buf_id)

    if win_id > 0
      execute win_id . "wincmd c"
      return

    else
      execute g:iron_repl_open_cmd[g:iron_repl_split_type] . " sbuffer " . g:iron_repl_buf_id 
      execute g:iron_repl_size_cmd[g:iron_repl_split_type]
    endif

  else
    execute g:iron_repl_open_cmd[g:iron_repl_split_type] . " term"
    execute g:iron_repl_size_cmd[g:iron_repl_split_type]
    let g:iron_repl_buf_id = bufnr('%')

    if has_key(g:iron_repl_def, ft)
      call term_sendkeys(g:iron_repl_buf_id, g:iron_repl_def[ft] . "\n")
    else
      call term_sendkeys(g:iron_repl_buf_id, ft . "\n")
    endif
 
    setlocal bufhidden=hide
    autocmd ExitPre * execute ':bd! ' . g:iron_repl_buf_id

  endif

  call win_gotoid(current_win_id)
endfunction

nnoremap <Leader>rr :call IronRepl('toggle')<CR>
nnoremap <Leader>rv :call IronRepl('vertical')<CR>
nnoremap <Leader>rh :call IronRepl('horizontal')<CR>

nnoremap <leader>sl :SlimeSend<CR>
nnoremap <leader>sp <Plug>SlimeParagraphSend<CR>
vnoremap <leader>sp <Plug>SlimeRegionSend<CR>

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
