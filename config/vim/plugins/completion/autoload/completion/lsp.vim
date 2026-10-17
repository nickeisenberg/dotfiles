vim9script

# The lsp engine: yegappan/lsp's own completion as you type, with words
# from the buffer added. For Vims without 'autocomplete'. There is no path
# source here (<C-x><C-f> still completes paths), and long items aren't cut:
# the condensed menu shows only names and kinds, with the details in the
# docs popup.

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
