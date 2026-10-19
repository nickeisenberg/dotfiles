vim9script

# Working with the hunks of the current buffer: jump between them, preview
# one, reset one to the base, and diff the whole file. Each takes the
# current buffer's state, with its hunks up to date (hunks#Current()).

import autoload './differ.vim'
import autoload './util.vim'

# ---------------------------------------------------------------------------
# ]c / [c
# ---------------------------------------------------------------------------

# Jump `count` hunks forward or back from the cursor, wrapping around the
# file when 'wrapscan' is set.
export def Nav(state: dict<any>, forward: bool, count: number)
  const starts = state.hunks->mapnew((_, h) => differ.Span(h)[0])
  if empty(starts)
    util.Warn('no hunks')
    return
  endif
  var lnum = line('.')
  var index = -1
  for _ in range(max([count, 1]))
    # The first hunk starting below lnum, or the last one starting above.
    index = -1
    for i in range(len(starts))
      if forward ? starts[i] > lnum : starts[i] < lnum
        index = i
        if forward
          break
        endif
      endif
    endfor
    if index < 0 && &wrapscan
      index = forward ? 0 : len(starts) - 1
    endif
    if index < 0
      util.Warn($'no more hunks {forward ? "below" : "above"}')
      return
    endif
    lnum = starts[index]
  endfor
  normal! m'
  cursor(lnum, 1)
  normal! ^
  echo $'Hunk {index + 1} of {len(starts)}'
enddef

# ---------------------------------------------------------------------------
# Preview
# ---------------------------------------------------------------------------

# A hunk as diff lines: the header, then its base lines as -, and its buffer
# lines as +. Header numbers are git's: 1-based, or with a count of 0, the
# line the change comes after.
export def DiffLines(state: dict<any>, h: dict<number>): list<string>
  const old_line = h.old_count == 0 ? h.old_start : h.old_start + 1
  const new_line = h.new_count == 0 ? h.new_start : h.new_start + 1
  var lines = [$'@@ -{old_line},{h.old_count} +{new_line},{h.new_count} @@']
  for line in slice(state.base, h.old_start, h.old_start + h.old_count)
    lines->add($'-{line}')
  endfor
  if h.new_count > 0
    for line in getbufline(bufnr(), h.new_start + 1, h.new_start + h.new_count)
      lines->add($'+{line}')
    endfor
  endif
  return lines
enddef

# Show the hunk on the cursor line in a popup, closed when the cursor moves.
export def Preview(state: dict<any>)
  const found = differ.Within(state.hunks, line('.'), line('.'))
  if empty(found)
    util.Warn('no hunk on this line')
    return
  endif
  const winid = popup_atcursor(DiffLines(state, found[0]), util.POPUP)
  win_execute(winid, 'setlocal filetype=diff')
enddef

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------

# Put the base's lines back for the hunks in the range, or the one on the
# cursor line (line1 and line2 without a range): one change, so `u` undoes
# it. Returns whether anything was reset.
export def Reset(state: dict<any>, line1: number, line2: number, has_range: bool): bool
  # Not const: its type is unknown until differ.vim loads, and Vim then
  # refuses the reverse() below even on a copy.
  var chosen = differ.Within(state.hunks, line1, line2)
  if empty(chosen)
    util.Warn(has_range ? 'no hunks in the range' : 'no hunk on this line')
    return false
  endif
  const bufnr = bufnr()
  # From the bottom up, so the hunks above keep their line numbers.
  for h in reverse(copy(chosen))
    const old = slice(state.base, h.old_start, h.old_start + h.old_count)
    const emptied = h.new_count > 0 && h.new_count == line('$')
    if h.new_count > 0
      deletebufline(bufnr, h.new_start + 1, h.new_start + h.new_count)
    endif
    if !empty(old)
      appendbufline(bufnr, h.new_start, old)
      # Deleting every line leaves one empty line, now after the base's.
      if emptied
        deletebufline(bufnr, '$')
      endif
    endif
  endfor
  return true
enddef

# ---------------------------------------------------------------------------
# Diff the whole file
# ---------------------------------------------------------------------------

# The base in a split on the left, read-only, in diff mode with the buffer.
# Wiping it out (:q) turns diff mode off in the buffer's window. A base
# split already open for the file is replaced.
export def DiffThis(state: dict<any>)
  const name = $'hunks://{state.base_name}/{state.relpath}'
  for b in getbufinfo()->filter((_, b) => b.name == name)
    execute $'bwipeout {b.bufnr}'
  endfor
  const filetype = &filetype
  const winid = win_getid()
  vertical leftabove new
  setline(1, state.base)
  setlocal buftype=nofile bufhidden=wipe noswapfile nomodifiable
  &l:filetype = filetype
  silent! execute 'file' fnameescape(name)
  diffthis
  execute $'autocmd BufWipeout <buffer> ++once win_execute({winid}, "diffoff")'
  win_gotoid(winid)
  diffthis
enddef
