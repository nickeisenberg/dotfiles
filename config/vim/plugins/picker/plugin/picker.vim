vim9script

# A fuzzy finder in popups, with a preview of the selected result.
#
#   picker#FindFiles()    files under the working directory (rg --files)
#   picker#LiveGrep()     search file contents as you type (rg --vimgrep)
#   picker#FindBuffers()  listed buffers
#   picker#References()   LSP references to the symbol under the cursor
#   picker#Definitions()  LSP definitions of the symbol under the cursor
#
# In the picker: type to filter, <C-n>/<C-p> or <Down>/<Up> to move, <CR>
# to open, <Esc> to close; <BS>, <C-w> and <C-u> edit the query.
