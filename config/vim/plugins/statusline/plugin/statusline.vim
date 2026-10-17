vim9script noclear

# A statusline: mode, branch, changes and path on the left; diagnostics,
# language servers, filetype and position on the right.
#
# Options (set before the plugin loads, or call statusline#Setup() after):
#   g:statusline_show   parts to show, e.g. {lsp: false}; all default on:
#                       mode, git, diff, diagnostics, lsp, filetype, position
#   g:statusline_icons  diagnostic labels, {error:, warn:, info:, hint:}

if exists('g:loaded_statusline')
  finish
endif
g:loaded_statusline = true

statusline#Setup()
