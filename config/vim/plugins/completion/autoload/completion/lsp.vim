vim9script

# The lsp engine (see plugin/completion.vim). There is no path source here
# (<C-x><C-f> still completes paths), and long items aren't cut: the
# condensed menu shows only names and kinds, with the details in the docs
# popup.

# yegappan/lsp has to load before this plugin.
export def Available(): bool
  return exists('g:loaded_lsp') == 1
enddef

export def Setup()
  completion#LspOptions({
    autoComplete: true,
    omniComplete: false,
    useBufferCompletion: true,
    condensedCompletionMenu: true,
  })
enddef
