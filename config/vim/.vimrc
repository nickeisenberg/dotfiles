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
set noswapfile
set background=dark
set relativenumber
" set cursorline
" set cursorcolumn

let &shell = &shell . " --login"

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
nnoremap <leader>P "+P
vnoremap <leader>P "+P

" Explorer
"--------------------------------------------------
nnoremap <leader>O :Ex<CR>

" quick write
"--------------------------------------------------
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!<CR>

"--------------------------------------------------

syntax on
filetype on
filetype plugin on

" plugins
"--------------------------------------------------

call plug#begin('~/.vim/plugged')
" autocompletion and lsp
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" file exploring
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'vifm/vifm.vim'

" git
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'
Plug 'mhinz/vim-signify'

" status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" markdown
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

" editor
Plug 'vim-python/python-syntax'
Plug 'Vimjas/vim-python-pep8-indent'
Plug 'ntpeters/vim-better-whitespace'
Plug 'wellle/context.vim'

" repl
Plug 'Vigemus/iron.vim', { 'branch': 'master' }
" Plug '~/gitrepos/iron.vim'
Plug 'nickeisenberg/float-term.vim'

call plug#end()

" if has('termguicolors') && v:version >= 900 && filereadable(expand("~/.vim/colors/rosepine.vim"))
"   colorscheme rosepine
"   highlight Normal ctermbg=233
" endif

"--------------------------------------------------
" plugin configs
"--------------------------------------------------

" coc.nvim setup
nnoremap <silent> K :call CocActionAsync('doHover')<CR>
nnoremap <leader>rn <Plug>(coc-rename)
nnoremap <leader>gd <Plug>(coc-definition)
nnoremap ]d <Plug>(coc-diagnostic-next)
nnoremap [d <Plug>(coc-diagnostic-prev)
command! -nargs=0 Format call CocAction('format')


" syntax highlighting
"--------------------------------------------------
let g:python_highlight_all = 1

" iron.vim
"--------------------------------------------------
if system("uname") == "Darwin\n"
  let g:iron_term_wait = 5
else
  let g:iron_term_wait = 1
endif

let g:iron_repl_open_cmd = {
  \ 'vertical': iron#view#split('vertical rightbelow', 0.4),
  \ 'horizontal': iron#view#split('rightbelow', 0.25),
\}

let g:iron_keymaps = {
  \ "toggle_repl": "<leader>rr",
  \ "toggle_vertical": "<leader>rv",
  \ "toggle_horizontal": "<leader>rh",
  \ "repl_restart": "<leader>rR",
  \ "repl_kill": "<leader>rk",
  \ "send_line": "<leader>sl",
  \ "send_visual": "<leader>sp",
  \ "send_paragraph": "<leader>sp",
  \ "send_until_cursor": "<leader>su",
  \ "send_file": "<leader>sf",
  \ "send_cancel": "<leader>sc",
  \ "send_blank_line": "<leader><CR>",
  \ "clear": "<leader>rc",
\ }

" vim-signify
"--------------------------------------------------
nnoremap <Leader>Sd :SignifyDiff<CR>
nnoremap <Leader>Sh :SignifyHunkDiff<CR>

" fzf
"--------------------------------------------------
nnoremap <Leader>ff :Files<CR>
nnoremap <Leader>fb :Buffers<CR>
nnoremap <Leader>fg :RG <CR>

" airline
"--------------------------------------------------
let g:airline_section_z = '%p%% %l:%c'
let g:airline#extensions#default#layout = [ ['a', 'b', 'c'], ['x', 'y', 'z'] ]
let g:airline#extensions#branch#enabled = 1
let g:airline_theme='base16'
