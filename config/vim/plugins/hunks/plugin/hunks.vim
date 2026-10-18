vim9script noclear

# Signs in the sign column for lines added, changed or removed against the
# git index (or a revision), updated as you type; and commands to jump
# between those hunks, preview, reset or stage them, and blame a line.
#
# Options (set before the plugin loads):
#   g:hunks_diff      how hunks are computed: 'auto' (default), 'builtin'
#                     (Vim's diff(), 9.1.0071 and later) or 'job'
#                     (`git diff --no-index` on temp files)
#   g:hunks_signs     sign text, e.g. {add: '┃'}; keys add, change, delete,
#                     topdelete, changedelete
#   g:hunks_priority  sign priority (default 5, below diagnostics)
#   g:hunks_base      what buffers are compared against: 'index' (default)
#                     or a revision such as 'HEAD'; :Hunks base changes it
#
# :Hunks toggle        signs on or off
# :Hunks refresh       fetch the base again
# :Hunks next [N]      jump to the Nth next hunk (prev: back), wrapping
#                      around with 'wrapscan'
# :Hunks preview       the hunk on the cursor line, in a popup
# :[range]Hunks reset  put back the base's lines for the hunk on the cursor
#                      line, or every hunk in the range; `u` undoes it
# :Hunks diffthis      the base in a split, in diff mode with the buffer
# :[range]Hunks stage  stage the hunk on the cursor line, or every hunk in
#                      the range, unsaved or not (needs the index as base)
# :Hunks undo_stage    put back the index entry from before the last stage
# :Hunks blame         the cursor line's commit and message, in a popup
# :Hunks base [REV]    compare against REV ('index', 'HEAD', ...) from now
#                      on; without REV, show the base

if exists('g:loaded_hunks')
  finish
endif
g:loaded_hunks = true

hunks#Setup()

command! -range -nargs=+ -complete=customlist,hunks#Complete Hunks hunks#Command(<q-args>, <line1>, <line2>, <range> > 0)
