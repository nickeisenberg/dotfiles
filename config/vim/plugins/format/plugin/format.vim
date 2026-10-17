vim9script noclear

# Format buffers on save with a pipeline of external tools, falling back to
# an attached language server's formatter.
#
#   g:format_formatters = {
#     lua: [['stylua', '-']],
#     python: [
#       ['ruff', 'check', '--fix', '--exit-zero', '--stdin-filename', '%', '-'],
#       ['ruff', 'format', '--stdin-filename', '%', '-'],
#     ],
#   }
#
# Each filetype maps to a list of steps run in order; the buffer goes to the
# first step on stdin and each step's stdout feeds the next. An argument
# that is exactly '%' becomes the buffer's file name. A step can also be a
# Funcref that takes the file name and returns the command list.
#
#   g:format_on_save     format before every write (default true)
#   g:format_timeout_ms  per step, and for the LSP request (default 5000)
#
# :Format formats the current buffer.

if exists('g:loaded_format')
  finish
endif
g:loaded_format = true

augroup format
  autocmd!
  autocmd BufWritePre * if get(g:, 'format_on_save', true) | format#Format(str2nr(expand('<abuf>'))) | endif
augroup END

command! -bar Format format#Format(bufnr())
