vim9script

# Staging hunks without a patch: the file's index entry is pointed at new
# content, the index version with the chosen hunks applied, stored with
# `git hash-object -w`. The buffer needn't be saved. Undoing points the
# entry back at what it was before.

import autoload './repo.vim'
import autoload './actions.vim'

# root/relpath -> the index entries replaced, [mode, object], oldest first.
var undo: dict<list<list<string>>> = {}

# The file's index entry, [mode, object], or [] when it has none.
def IndexEntry(state: dict<any>): list<string>
  # Literal, or a name like [0-9].txt would match 1.txt too.
  const result = repo.Git(state.root, ['ls-files', '--stage', '--', $':(literal){state.relpath}'])
  const m = matchlist(result.output, '^\(\d\+\) \(\x\+\) 0\t')
  return !result.ok || empty(m) ? [] : [m[1], m[2]]
enddef

def SetEntry(state: dict<any>, entry: list<string>): bool
  return repo.Git(state.root, ['update-index', '--cacheinfo',
    $'{entry[0]},{entry[1]},{state.relpath}']).ok
enddef

# The text of the base with `hunks` applied from the buffer's `lines`.
export def Applied(state: dict<any>, lines: list<string>, hunks: list<dict<number>>,
    buffer_eol: bool): string
  var staged: list<string> = []
  var pos = 0
  for h in hunks
    staged->extend(slice(state.base, pos, h.old_start))
    staged->extend(slice(lines, h.new_start, h.new_start + h.new_count))
    pos = h.old_start + h.old_count
  endfor
  staged->extend(slice(state.base, pos))
  # The last line ends as the base's does, unless the last hunk reaches the
  # end of both: then as the buffer would be written.
  var eol = state.eol
  const last = hunks[-1]
  if last.old_start + last.old_count == len(state.base)
      && last.new_start + last.new_count == len(lines)
    eol = buffer_eol
  endif
  const nl = state.crlf ? "\r\n" : "\n"
  return join(staged, nl) .. (eol && !empty(staged) ? nl : '')
enddef

# Stage the hunk on the cursor line, or every hunk in the range.
export def Stage(line1: number, line2: number, has_range: bool)
  const state = actions.Tracked()
  if empty(state)
    return
  endif
  if state.base_name != 'index'
    actions.Warn($'staging needs the index as the base, not {state.base_name} (:Hunks base index)')
    return
  endif
  const chosen = actions.Chosen(state.hunks, line1, line2, has_range)
  if empty(chosen)
    actions.Warn(has_range ? 'no hunks in the range' : 'no hunk on this line')
    return
  endif
  const entry = IndexEntry(state)
  if empty(entry)
    actions.Warn('the file has no index entry to stage into')
    return
  endif

  var lines = getline(1, '$')
  if lines == [''] && empty(state.base)
    lines = []
  endif
  const text = Applied(state, lines, chosen, &endofline || &fixendofline)
  const hashed = repo.Git(state.root, ['hash-object', '-w', '--stdin'], text)
  if !hashed.ok || !SetEntry(state, [entry[0], trim(hashed.output)])
    actions.Warn($'git failed: {trim(hashed.output)}')
    return
  endif
  const key = $'{state.root}/{state.relpath}'
  undo[key] = undo->get(key, [])->add(entry)
  hunks#Refresh(bufnr(), true)
  echo $'hunks: staged {len(chosen)} hunk{len(chosen) == 1 ? "" : "s"}'
enddef

# Put back the index entry from before the last :Hunks stage on this file.
export def UndoStage()
  const state = actions.Tracked()
  if empty(state)
    return
  endif
  const key = $'{state.root}/{state.relpath}'
  if empty(undo->get(key, []))
    actions.Warn('nothing staged here to undo')
    return
  endif
  const entry = remove(undo[key], -1)
  if !SetEntry(state, entry)
    actions.Warn('git update-index failed')
    return
  endif
  hunks#Refresh(bufnr(), true)
  echo 'hunks: unstaged'
enddef
