vim9script

# Reading files for the preview, and highlighting them.

import autoload './util.vim'

# Bound preview reads so large files are not loaded in full.
const MAX_BYTES = 256 * 1024
const TOO_BIG = $'[Preview disabled: larger than {MAX_BYTES / 1024} KiB]'

# The lines to show for `path`, and whether they are its text (false for a
# message such as "[binary file]").
export def ReadFile(path: string): list<any>
  const bufnr = util.LoadedBuffer(path)

  # Prefer the loaded buffer so unsaved edits appear in the preview.
  if bufnr > 0
    const lines = getbufline(bufnr, 1, '$')
    if lines->reduce((acc, l) => acc + len(l) + 1, 0) > MAX_BYTES
      return [[TOO_BIG], false]
    endif
    if lines == ['']
      return [['[Empty file]'], false]
    endif
    return [lines, true]
  endif

  const size = getfsize(path)
  if size < 0 || !filereadable(path)
    return [['[Unable to read file]'], false]
  endif
  if size > MAX_BYTES
    return [[TOO_BIG], false]
  endif
  if size == 0
    return [['[Empty file]'], false]
  endif

  # readfile() turns NUL bytes into "\n" within a line, so one read tells a
  # binary file apart.
  var lines = readfile(path)
  if match(lines, "\n") >= 0
    return [['[Preview disabled: binary file]'], false]
  endif
  # readfile() splits on "\n"; drop the "\r" of Windows line endings.
  return [lines->map((_, l) => l->substitute('\r$', '', '')), true]
enddef

# Syntax-highlight the preview popup `win` as `file`'s filetype.
#
# The filetype is found the way Vim finds it when opening the file, but
# with FileType events ignored: they would run ftplugins and start language
# servers for a buffer that only exists to be looked at. Only the 'syntax'
# option is set from the result.
export def Highlight(win: number, file: string)
  const saved = &eventignore
  set eventignore+=FileType
  try
    win_execute(win, 'setlocal filetype=')
    win_execute(win, $'silent! doautocmd filetypedetect BufRead {fnameescape(file)}')
    const ft = getbufvar(winbufnr(win), '&filetype')
    win_execute(win, 'setlocal filetype=')
    win_execute(win, $'setlocal syntax={empty(ft) ? "OFF" : ft}')
  finally
    &eventignore = saved
  endtry
enddef
