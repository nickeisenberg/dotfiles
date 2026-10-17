vim9script

# Picks a completion engine and sets it up.
#
# Each engine is a script in autoload/completion/ that exports two
# functions: Available(), true when it can run in this Vim, and Setup().
#   builtin  Vim's 'autocomplete' with path, LSP and buffer sources
#   lsp      yegappan/lsp's own completion, for Vims without 'autocomplete'
#
# g:completion_engine is 'auto' (the default: builtin when available, else
# lsp), 'builtin' or 'lsp'.

import autoload './completion/builtin.vim'
import autoload './completion/lsp.vim' as lsp_engine

def Notify(msg: string)
  echohl WarningMsg
  echomsg $'completion: {msg}'
  echohl None
enddef

# Options for yegappan/lsp that wait for it to load.
var pending: dict<any> = {}

def SetPending()
  if exists('*g:LspOptionsSet')
    g:LspOptionsSet(pending)
  endif
enddef

# Hand options to yegappan/lsp, now or, when it isn't loaded yet, once Vim
# has started. Option sets are merged, so the vimrc's own stay.
export def LspOptions(opts: dict<any>)
  if exists('*g:LspOptionsSet')
    g:LspOptionsSet(opts)
    return
  endif
  pending->extend(opts)
  augroup completion_lsp_options
    autocmd!
    autocmd VimEnter * ++once SetPending()
  augroup END
enddef

export def Setup()
  const wanted = get(g:, 'completion_engine', 'auto')

  if wanted == 'builtin' || wanted == 'auto'
    if builtin.Available()
      builtin.Setup()
      return
    endif
    if wanted == 'builtin'
      Notify("this Vim has no 'autocomplete'; using the lsp engine")
    endif
  elseif wanted != 'lsp'
    Notify($'unknown engine "{wanted}"; using auto')
    g:completion_engine = 'auto'
    Setup()
    return
  endif

  if lsp_engine.Available()
    lsp_engine.Setup()
  elseif wanted == 'lsp'
    Notify('the lsp engine needs yegappan/lsp')
  endif
enddef
