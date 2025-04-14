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
set cursorline
set cursorcolumn
set noswapfile
set background=dark

syntax on
filetype on
filetype plugin on

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

"--------------------------------------------------

" plugins
"--------------------------------------------------

call plug#begin('~/.vim/plugged')
" autocompletion

Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'prabirshrestha/asyncomplete-file.vim'

if has('python3')
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
  Plug 'prabirshrestha/asyncomplete-ultisnips.vim'
else
  Plug 'Shougo/neosnippet.vim'
  Plug 'Shougo/neosnippet-snippets'
  Plug 'prabirshrestha/asyncomplete-neosnippet.vim'
endif

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
" Plug '~/gitrepos/vigemus/iron.vim'
Plug 'nickeisenberg/float-term.vim'

call plug#end()

colorscheme rosepine
highlight Normal ctermbg=233

"--------------------------------------------------
" plugin configs
"--------------------------------------------------

" LSP
"--------------------------------------------------
let g:lsp_diagnostics_virtual_text_enabled = 1
let g:lsp_diagnostics_virtual_text_insert_mode_enabled = 0
let g:lsp_diagnostics_virtual_text_align = "right"
let g:lsp_diagnostics_virtual_text_delay = 0

function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
  nmap <buffer> <leader>gd <plug>(lsp-definition)
  nmap <buffer> <leader>gr <plug>(lsp-references)
  nmap <buffer> <leader>gi <plug>(lsp-implementation)
  nmap <buffer> <leader>gt <plug>(lsp-type-definition)
  nmap <buffer> <leader>rn <plug>(lsp-rename)
  nmap <buffer> [d <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]d <plug>(lsp-next-diagnostic)
  nmap <buffer> K <plug>(lsp-hover)
  nnoremap <buffer> <expr><c-n> lsp#scroll(+4)
  nnoremap <buffer> <expr><c-p> lsp#scroll(-4)

  autocmd User lsp_buffer_enabled
    \ autocmd! BufWritePre <buffer>
    \ call execute('LspDocumentFormatSync')
endfunction

augroup lsp_install
  au!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

au User asyncomplete_setup call asyncomplete#register_source(
  \ asyncomplete#sources#file#get_source_options({
    \ 'name': 'file',
    \ 'allowlist': ['*'],
    \ 'priority': 10,
    \ 'completor': function('asyncomplete#sources#file#completor')
  \ })
\ )

if executable('pyright')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyright',
        \ 'cmd': {server_info->['pyright-langserver', '--stdio']},
        \ 'allowlist': ['python'],
        \ })
endif

if executable('bash-language-server')
  au User lsp_setup call lsp#register_server({
    \ 'name': 'bash-language-server',
    \ 'cmd': {server_info->['bash-language-server', 'start']},
    \ 'allowlist': ['sh'],
    \ })
endif

if executable('vim-language-server')
  au User lsp_setup call lsp#register_server({
    \ 'name': 'vimls',
    \ 'cmd': {server_info->['vim-language-server', '--stdio']},
    \ 'allowlist': ['vim'],
    \ })
endif

if executable('ruff')
  au User lsp_setup call lsp#register_server({
    \ 'name': 'ruff',
    \ 'cmd': {server_info->['ruff', 'server', '--preview']},
    \ 'allowlist': ['python'],
    \ })
endif

if &filetype ==# 'python'
    command! -buffer RuffFix execute 'write'
        \ | silent execute '!ruff check --fix %'
        \ | silent edit!
        \ | call execute('LspDocumentFormatSync')
endif

if has('python3')
  let g:UltiSnipsExpandTrigger="<c-y>"
  call asyncomplete#register_source(asyncomplete#sources#ultisnips#get_source_options({
    \ 'name': 'ultisnips',
    \ 'allowlist': ['*'],
    \ 'completor': function('asyncomplete#sources#ultisnips#completor'),
    \ }))
else
  imap <C-y>     <Plug>(neosnippet_expand_or_jump)
  smap <C-y>     <Plug>(neosnippet_expand_or_jump)
  xmap <C-y>     <Plug>(neosnippet_expand_target)
  call asyncomplete#register_source(asyncomplete#sources#neosnippet#get_source_options({
     \ 'name': 'neosnippet',
     \ 'allowlist': ['*'],
     \ 'completor': function('asyncomplete#sources#neosnippet#completor'),
     \ }))
endif


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
  \ "send_blank_line": "<leader>s<CR>",
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
