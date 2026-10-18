" Directory buffers of files.nvim: hide the number each line starts with
" ("/12 name"), even when an edit has eaten the space after it.
if exists('b:current_syntax')
  finish
endif
syntax match FilesId /^\/\d\+ \?/ conceal
let b:current_syntax = 'files'
