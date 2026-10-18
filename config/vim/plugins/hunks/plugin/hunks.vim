vim9script noclear

# Signs in the sign column for lines added, changed or removed against the
# git index, updated as you type.
#
# Options (set before the plugin loads):
#   g:hunks_diff      how hunks are computed: 'auto' (default), 'builtin'
#                     (Vim's diff(), 9.1.0071 and later) or 'job'
#                     (`git diff --no-index` on temp files)
#   g:hunks_signs     sign text, e.g. {add: '┃'}; keys add, change, delete,
#                     topdelete, changedelete
#   g:hunks_priority  sign priority (default 5, below diagnostics)
#
# :Hunks toggle    signs on or off
# :Hunks refresh   fetch the base again

if exists('g:loaded_hunks')
  finish
endif
g:loaded_hunks = true

hunks#Setup()

command! -range -nargs=+ -complete=customlist,hunks#Complete Hunks hunks#Command(<q-args>, <line1>, <line2>, <range> > 0)
