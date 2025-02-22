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

" slime
"--------------------------------------------------
let g:slime_target = "vimterminal"

" vim-floaterm
"--------------------------------------------------
nnoremap <Leader>rr :FloatermToggle<CR>
nnoremap <Leader>rk :FloatermKill<CR>

let g:floaterm_wintype = 'vsplit'
let g:floaterm_position = 'botright'
let g:floaterm_width = 0.4

if exists('$VIRTUAL_ENV')
  let g:floaterm_shell = $SHELL . ' -c "source $VIRTUAL_ENV/bin/activate && exec $SHELL"'
else
  let g:floaterm_shell = $SHELL
endif

function! ToggleTerminal(where)
  if a:where ==# "horizontal"
    let g:floaterm_wintype = 'split'
    let g:floaterm_position = 'rightbelow'
    let g:floaterm_height = 0.4
    FloatermToggle
  elseif a:where ==# "vertical"
    let g:floaterm_wintype = 'vsplit'
    let g:floaterm_position = 'botright'
    let g:floaterm_width = 0.4
    FloatermToggle
  elseif a:where ==# "float"
    let g:floaterm_wintype = 'float'
    let g:floaterm_position = 'center'
    let g:floaterm_width = 0.6
    let g:floaterm_width = 0.6
    FloatermToggle
  endif
endfunction

nnoremap <Leader>rv :call ToggleTerminal('vertical')<CR>
nnoremap <Leader>rh :call ToggleTerminal('horizontal')<CR>
nnoremap <Leader>rf :call ToggleTerminal('float')<CR>

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
