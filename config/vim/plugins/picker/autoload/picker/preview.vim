vim9script

# Reading files for the preview, and highlighting them.

# Bound preview reads so large files are not loaded in full.
const MAX_BYTES = 256 * 1024

export def ReadFile(path: string): list<string>
  const bufnr = bufnr(path)

  # Prefer the loaded buffer so unsaved edits appear in the preview.
  if bufnr > 0 && bufloaded(bufnr)
    const lines = getbufline(bufnr, 1, '$')
    if lines->reduce((acc, l) => acc + len(l) + 1, 0) > MAX_BYTES
      return ['[Preview disabled: buffer exceeds 256 KiB]']
    endif
    if lines == ['']
      return ['[empty file]']
    endif
    return lines
  endif

  const size = getfsize(path)
  if size < 0 || !filereadable(path)
    return ['Unable to preview file']
  endif
  if size > MAX_BYTES
    return ['[Preview disabled: file exceeds 256 KiB]']
  endif
  if size == 0
    return ['[empty file]']
  endif

  # Avoid displaying binary data in the text preview.
  if readblob(path, 0, 8192)->index(0) >= 0
    return ['[Preview disabled: binary file]']
  endif

  # readfile() splits on "\n"; drop the "\r" of Windows line endings.
  return readfile(path)->map((_, l) => l->substitute('\r$', '', ''))
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
