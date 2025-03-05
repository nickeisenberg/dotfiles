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
set nocompatible

let &shell = &shell . ' --login'

" move to the next/prev paragraph without opening folds
"--------------------------------------------------
nnoremap <expr> } foldclosed('.') == -1 ? '}' : 'j'
vnoremap <expr> } foldclosed('.') == -1 ? '}' : 'j'
nnoremap <expr> { foldclosed('.') == -1 ? '{' : 'k'
vnoremap <expr> { foldclosed('.') == -1 ? '{' : 'k'

" splits
"--------------------------------------------------
nnoremap <Leader>cs :close<CR>
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

" These are redunant if vim plug is active. But needed if only packadd is used
syntax on
filetype on
filetype plugin on
"--------------------------------------------------

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

call plug#end()

" .vim/colors/rosepine.vim
"--------------------------------------------------
colorscheme rosepine
highlight Normal ctermbg=NONE guibg=#141415

"--------------------------------------------------
" plugin configs
"--------------------------------------------------

" iron.vim
"---------"-----------------------------------------
if !empty($VIRTUAL_ENV)
  let python_def = "source $VIRTUAL_ENV/bin/activate && clear && which python3 && ipython --no-autoindent"
else
  let python_def = "ipython --no-autoindent"
endif

let g:iron_repl_def = {
  \'sh': 'bash -l',
  \'vim': 'bash -l',
  \'python': python_def,
  \}


" NERDTree
"--------------------------------------------------
let g:NERDTreeMapActivateNode = ''
let g:NERDTreeMapOpenInTab = 'o'
nnoremap <Leader>O :NERDTreeExplore<CR>

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
