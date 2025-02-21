let mapleader = " "

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
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'mhinz/vim-signify'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

" plugin configs
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

    " Get virtual environment path
    let venv_path = $VIRTUAL_ENV

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
                execute "rightbelow sbuffer " . term_buf
            endif
        endif
    else
        " Define shell script path
        let shell_script = "/tmp/activate_venv.sh"

        " Create the shell script that will activate the venv and start a shell
        if !empty(venv_path)
            call writefile([
                        \ "#!/bin/bash",
                        \ "source " . venv_path . "/bin/activate",
                        \ "exec " . &shell,
                        \ ], shell_script)
            call system("chmod +x " . shell_script)
        else
            let shell_script = &shell  " If no venv is active, just use the default shell"
        endif

        " Open the terminal in the appropriate split type
        if a:split_type ==# 'vertical'
            execute "vert botright term ++shell=" . shellescape(shell_script)
        else
            execute "rightbelow term ++shell=" . shellescape(shell_script)
        endif
        setlocal bufhidden=hide
    endif
endfunction

nnoremap <Leader>rv :call ToggleTerminal('vertical')<CR>
nnoremap <Leader>rh :call ToggleTerminal('horizontal')<CR>

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
