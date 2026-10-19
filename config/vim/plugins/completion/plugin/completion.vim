vim9script noclear

# Completion as you type, with one of two engines:
#   builtin  Vim's own 'autocomplete' (9.1.1638 and later). Vim collects
#            items from every source in 'complete' and merges them into one
#            menu, giving slow sources less time; this plugin picks the
#            sources and adds path and LSP sources of its own. The LSP
#            source waits up to a second for the server, unless a key is
#            typed first.
#   lsp      yegappan/lsp's own completion, plus buffer words, for older
#            Vims. yegappan/lsp must be loaded before this plugin.
#
# Options are read when the plugin loads. completion#Setup() applies changed
# options again, but not a change of engine: that needs a restart.
#   g:completion_engine     'auto' (builtin when available, else lsp),
#                           'builtin' or 'lsp'
#
# For the builtin engine:
#   g:completion_sources    priority order, default ['path', 'lsp', 'buffer']
#   g:completion_max_items  source -> most items each of its 'complete'
#                           flags may add, e.g. {lsp: 50}; buffer has three
#                           (this buffer, other windows, other buffers)
#   g:completion_delay_ms   wait after typing before the menu opens (0)
#   g:completion_fuzzy      fuzzy matching (true)
#   g:completion_docs       docs popup for the selected item (true)
#   g:completion_max_width  widest LSP name/detail columns, cut with "…"
#                           ({abbr: 40, menu: 30}; 0 means no limit; a key
#                           left out keeps its default)
#   g:completion_path       {relative_to: 'buffer' or 'cwd', hidden: true}
#                           (hidden: list dotfiles, after the other names,
#                           even before a "." is typed)
#
# Keys are Vim's: <C-n>/<C-p> move through the menu, <C-y> accepts, <C-e>
# closes it.

if exists('g:loaded_completion')
  finish
endif
g:loaded_completion = true

completion#Setup()
