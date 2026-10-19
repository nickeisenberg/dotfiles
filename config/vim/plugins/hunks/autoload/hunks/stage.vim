vim9script

# Staging hunks without a patch: the file's index entry is pointed at new
# content, the index version with the chosen hunks applied, stored with
# `git hash-object -w`. The buffer needn't be saved. Undoing points the
# entry back at what it was before. Both take the current buffer's state,
# with its hunks up to date (hunks#Current()).

import autoload './repo.vim'
import autoload './differ.vim'
import autoload './util.vim'

# root/relpath -> the stages made, oldest first: {before, after, head}, the
# index entry ([mode, object]) each replaced, the one it put in, and the
# commit HEAD was at.
var undo: dict<list<dict<any>>> = {}

# The file's index entry, [mode, object], or [] when it has none.
def IndexEntry(state: dict<any>): list<string>
  # Literal, or a name like [0-9].txt would match 1.txt too.
  const result = repo.Git(state.root, ['ls-files', '--stage', '--', $':(literal){state.relpath}'])
  const m = matchlist(result.output, '^\(\d\+\) \(\x\+\) 0\t')
  return !result.ok || empty(m) ? [] : [m[1], m[2]]
enddef

# The commit HEAD is at, or '' before the first commit.
def Head(state: dict<any>): string
  return trim(repo.Git(state.root, ['rev-parse', '--verify', '--quiet', 'HEAD']).output)
enddef

# Point the file's index entry at `entry`; '' when done, else git's error.
def SetEntry(state: dict<any>, entry: list<string>): string
  const result = repo.Git(state.root, ['update-index', '--cacheinfo',
    $'{entry[0]},{entry[1]},{state.relpath}'])
  return result.ok ? '' : $'git update-index failed: {trim(result.error)}'
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

# Stage the hunk on the cursor line, or every hunk in the range (line1 and
# line2 without a range). Returns whether the index changed.
export def Stage(state: dict<any>, line1: number, line2: number, has_range: bool): bool
  if state.base_name != 'index'
    util.Warn($'staging needs the index as the base, not {state.base_name} (:Hunks base index)')
    return false
  endif
  const chosen = differ.Within(state.hunks, line1, line2)
  if empty(chosen)
    util.Warn(has_range ? 'no hunks in the range' : 'no hunk on this line')
    return false
  endif
  const entry = IndexEntry(state)
  if empty(entry)
    util.Warn('the file has no index entry to stage into')
    return false
  endif

  const lines = util.Lines(bufnr(), state.base)
  const text = Applied(state, lines, chosen, &endofline || &fixendofline)
  const hashed = repo.Git(state.root, ['hash-object', '-w', '--stdin'], text)
  if !hashed.ok
    util.Warn($'git hash-object failed: {trim(hashed.error)}')
    return false
  endif
  const staged = [entry[0], trim(hashed.output)]
  const error = SetEntry(state, staged)
  if !empty(error)
    util.Warn(error)
    return false
  endif
  const key = $'{state.root}/{state.relpath}'
  undo[key] = undo->get(key, [])->add({before: entry, after: staged, head: Head(state)})
  echo $'hunks: staged {len(chosen)} hunk{len(chosen) == 1 ? "" : "s"}'
  return true
enddef

# Put back the index entry from before the last :Hunks stage on this file.
# Not after a `git add` of the file or a commit since: that would undo
# more than the stage. Returns whether the index changed.
export def UndoStage(state: dict<any>): bool
  const key = $'{state.root}/{state.relpath}'
  var stages = undo->get(key, [])
  if !empty(stages) && (IndexEntry(state) != stages[-1].after || Head(state) != stages[-1].head)
    remove(undo, key)
    util.Warn('the index or HEAD has changed since the last stage, not undoing it')
    return false
  endif
  if empty(stages)
    util.Warn('nothing staged here to undo')
    return false
  endif
  const error = SetEntry(state, stages[-1].before)
  if !empty(error)
    util.Warn(error)
    return false
  endif
  remove(stages, -1)
  echo 'hunks: unstaged'
  return true
enddef
