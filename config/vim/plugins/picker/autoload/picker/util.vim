vim9script

# Small helpers the pickers share.

export def Notify(msg: string, error = false)
  if error
    echohl ErrorMsg
  endif
  echomsg $'picker: {msg}'
  if error
    echohl None
  endif
enddef

# The loaded buffer whose name is exactly `file`, or -1. Not bufnr(file):
# that takes a pattern, so it can pick another buffer whose name merely
# contains `file`, and treats "*?[" as wildcards.
export def LoadedBuffer(file: string): number
  const full = fnamemodify(file, ':p')
  for b in getbufinfo({bufloaded: 1})
    if b.name == full
      return b.bufnr
    endif
  endfor
  return -1
enddef

# Fuzzy-filter `items` (dicts) on their `key`. Through call(): Vim 9.0
# types matchfuzzy() as returning strings even for a list of dicts, so a
# direct call fails to compile there.
export def FuzzyByKey(items: list<dict<any>>, query: string, key: string): list<dict<any>>
  return call('matchfuzzy', [items, query, {key: key}])
enddef

# "file:lnum:col: text", how a location is shown in the result list.
export def LocationText(file: string, lnum: number, col: number, text: string): string
  return printf('%s:%d:%d: %s', file, lnum, col, text)
enddef

# Open `loc` ({file, lnum, col}) and put the cursor on it.
export def OpenLocation(loc: dict<any>)
  execute 'edit' fnameescape(loc.file)
  cursor(min([loc.lnum, line('$')]), max([loc.col, 1]))
  normal! zz
enddef
