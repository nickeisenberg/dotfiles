vim9script

# Picks the engine named by g:completion_engine (see plugin/completion.vim)
# and sets it up. Each engine is a script in autoload/completion/ that
# exports Available(), true when it can run in this Vim, and Setup().

import autoload './completion/builtin.vim'
import autoload './completion/lsp.vim' as lsp_engine

export def Notify(msg: string)
  echohl WarningMsg
  echomsg $'completion: {msg}'
  echohl None
enddef

# Hand options to yegappan/lsp. Option sets are merged, so the vimrc's own
# stay. When it isn't loaded yet they go in g:lsp_options, which it reads
# when it loads.
export def LspOptions(opts: dict<any>)
  if exists('*g:LspOptionsSet')
    g:LspOptionsSet(opts)
  else
    g:lsp_options = get(g:, 'lsp_options', {})->extend(opts)
  endif
enddef

export def Setup()
  var wanted = get(g:, 'completion_engine', 'auto')
  if index(['auto', 'builtin', 'lsp'], wanted) < 0
    Notify($'unknown engine "{wanted}"; using auto')
    wanted = 'auto'
  endif

  if wanted != 'lsp'
    if builtin.Available()
      builtin.Setup()
      return
    endif
    if wanted == 'builtin'
      Notify("this Vim's 'autocomplete' is missing or too old; using the lsp engine")
    endif
  endif

  if lsp_engine.Available()
    lsp_engine.Setup()
  elseif wanted == 'lsp'
    Notify('the lsp engine needs yegappan/lsp')
  endif
enddef
