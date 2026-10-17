vim9script noclear

# Completion as you type, built on Vim's own 'autocomplete'.
#
# Vim collects items from every source in 'complete', merges them into one
# menu and keeps slow sources from holding up typing. This plugin picks the
# sources and adds path and LSP sources of its own.
#
# Options (read when the plugin loads; call completion#Setup() to reapply):
#   g:completion_sources    priority order, default ['path', 'lsp', 'buffer']
#   g:completion_max_items  source -> most items it may add, e.g. {lsp: 50}
#   g:completion_delay_ms   wait after typing before the menu opens (0)
#   g:completion_fuzzy      fuzzy matching (true)
#   g:completion_docs       docs popup for the selected item (true)
#   g:completion_max_width  widest LSP name/detail columns, cut with "…"
#                           ({abbr: 40, menu: 30}; 0 means no limit)
#   g:completion_path       {relative_to: 'buffer' or 'cwd', hidden: true}
#
# Keys are Vim's: <C-n>/<C-p> move through the menu, <C-y> accepts, <C-e>
# closes it.

if exists('g:loaded_completion')
  finish
endif
g:loaded_completion = true

completion#Setup()
