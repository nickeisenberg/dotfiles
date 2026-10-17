vim9script noclear

# Terminals in a floating popup: toggle it, open more, cycle between them.
#
#   float_term#Toggle()  show or hide the popup (opens a terminal if none)
#   float_term#New()     open another terminal
#   float_term#Next()    show the next terminal
#   float_term#Prev()    show the previous terminal
#   float_term#Kill()    close the current terminal
#   float_term#KillAll() close every terminal
#
# Hiding the popup keeps the shells running. From the terminal, <C-\><C-n>
# (or <C-w>N) goes to Normal mode, where the mappings work.

if exists('g:loaded_float_term')
  finish
endif
g:loaded_float_term = true
