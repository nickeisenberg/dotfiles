vim9script

# Who last changed the cursor line, and the full commit message, in a
# popup. The buffer is blamed as it is, saved or not: lines you have
# changed show as not committed yet.

import autoload './repo.vim'
import autoload './actions.vim'

# The fields of `git blame --porcelain` for one line: {commit, author,
# author-time, summary, ...}.
export def ParsePorcelain(output: list<string>): dict<string>
  var info: dict<string> = {}
  if empty(output)
    return info
  endif
  info.commit = matchstr(output[0], '^\x\+')
  for line in output[1 :]
    if line =~ '^\t'
      break
    endif
    const m = matchlist(line, '^\(\S\+\) \(.*\)$')
    if !empty(m)
      info[m[1]] = m[2]
    endif
  endfor
  return info
enddef

# The popup's lines for a blamed line.
export def Lines(root: string, info: dict<string>): list<string>
  if info.commit =~ '^0\+$'
    return ['Not committed yet']
  endif
  const date = strftime('%Y-%m-%d %H:%M', str2nr(info->get('author-time', '0')))
  var lines = [$'{info.commit[: 7]}  {info->get("author", "?")}  {date}', '']
  var message = repo.Git(root, ['show', '-s', '--format=%B', info.commit]).output->split("\n", true)
  while !empty(message) && message[-1] =~ '^\s*$'
    remove(message, -1)
  endwhile
  return lines->extend(message)
enddef

# The popup's lines for line `lnum` of the current buffer, or [] after a
# warning.
export def ForLine(state: dict<any>, lnum: number): list<string>
  # With the file's line endings, so unchanged lines match the committed
  # ones.
  const nl = state.crlf ? "\r\n" : "\n"
  const contents = join(getline(1, '$'), nl) .. (&endofline ? nl : '')
  const result = repo.Git(state.root, ['blame', '--porcelain', '-L', $'{lnum},{lnum}',
    '--contents', '-', '--', state.relpath], contents)
  if !result.ok
    actions.Warn($'git blame failed: {trim(result.output)}')
    return []
  endif
  return Lines(state.root, ParsePorcelain(split(result.output, "\n")))
enddef

export def Blame()
  const state = actions.Tracked()
  if empty(state)
    return
  endif
  const lines = ForLine(state, line('.'))
  if empty(lines)
    return
  endif
  popup_atcursor(lines, {
    border: [],
    borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
    padding: [0, 1, 0, 1],
  })
enddef
