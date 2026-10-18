vim9script

# Per-buffer state and the autocmds that keep it current: the file's text at
# the base (fetched again when the index or HEAD moves), and the hunks
# between that and the buffer (computed again as you edit).

import autoload './hunks/repo.vim'
import autoload './hunks/differ.vim'
import autoload './hunks/signs.vim'
import autoload './hunks/actions.vim'

# bufnr -> {
#   path, root, relpath      the file, its repository, its path in there
#   stamp, base_name         when the base was fetched, and at what base
#   base, eol                the base's lines, and whether it ends with a
#                            newline; missing until fetched
#   hunks                    from the last diff
#   fetch_seq, fetch_job     the latest fetch; an older one is ignored
# }
var bufs: dict<dict<any>> = {}

var enabled = true

def Path(bufnr: number): string
  const name = bufname(bufnr)
  if empty(name) || !empty(getbufvar(bufnr, '&buftype'))
    return ''
  endif
  return resolve(fnamemodify(name, ':p'))
enddef

# The state of a buffer whose base has been fetched, else {}.
export def State(bufnr: number): dict<any>
  const state = bufs->get(bufnr, {})
  return has_key(state, 'base') ? state : {}
enddef

export def BaseName(): string
  return get(g:, 'hunks_base', 'index')
enddef

def Detach(bufnr: number)
  if has_key(bufs, bufnr)
    const state = bufs[bufnr]
    if has_key(state, 'fetch_job') && job_status(state.fetch_job) == 'run'
      job_stop(state.fetch_job)
    endif
    remove(bufs, bufnr)
  endif
  signs.Clear(bufnr)
  differ.Forget(bufnr)
enddef

# Diff the buffer against its base and place the signs. Skipped while the
# base is still being fetched. state.tick is the changedtick the hunks are
# for, and state.diff_tick the one last asked for.
export def Update(bufnr: number)
  const state = State(bufnr)
  if empty(state) || !bufloaded(bufnr)
    return
  endif
  const tick = getbufvar(bufnr, 'changedtick')
  state.diff_tick = tick
  var lines = getbufline(bufnr, 1, '$')
  # An empty buffer still has one empty line.
  if lines == [''] && empty(state.base)
    lines = []
  endif
  differ.Hunks(bufnr, state.base, lines, (hunks) => {
    # Drop a result that a later edit or fetch has overtaken.
    if State(bufnr) isnot state || getbufvar(bufnr, 'changedtick') != tick
      return
    endif
    state.hunks = hunks
    state.tick = tick
    if enabled
      signs.Place(bufnr, hunks)
    endif
  })
enddef

# The state with hunks for the buffer as it is now, for the commands: diffs
# if needed and waits for it (a few ms with the job backend, up to a second
# while the base is fetched). {} when the buffer isn't tracked.
export def Current(bufnr: number): dict<any>
  for _ in range(200)
    if !has_key(bufs, bufnr)
      return {}
    endif
    const state = State(bufnr)
    const tick = getbufvar(bufnr, 'changedtick')
    if !empty(state)
      if state->get('tick', -1) == tick
        return state
      elseif state->get('diff_tick', -1) != tick
        Update(bufnr)
        continue
      endif
    endif
    sleep 5m
  endfor
  return {}
enddef

# Fetch the base if it may have changed, else just diff again (unless
# `diff_anyway` is false: a CursorHold only checks for a new base).
export def Refresh(bufnr: number, force = false, diff_anyway = true)
  const path = Path(bufnr)
  const root = empty(path) ? '' : repo.Root(path)
  if empty(root)
    Detach(bufnr)
    return
  endif

  const stamp = repo.Stamp(root)
  const base_name = BaseName()
  var state = bufs->get(bufnr, {})
  if !force && !empty(state) && state.path == path && state.stamp == stamp
      && state.base_name == base_name
    if diff_anyway
      Update(bufnr)
    endif
    return
  endif

  if empty(state) || state.path != path
    state = {path: path, root: root, relpath: strpart(path, len(root) + 1),
             hunks: [], fetch_seq: 0}
    bufs[bufnr] = state
  endif
  # File times are in whole seconds: when the index or HEAD changed in this
  # second, another change in the same second would leave the stamp alone,
  # so leave it unset and fetch again on the next check.
  state.stamp = localtime() <= max([stamp[0], stamp[2]]) ? [] : stamp
  state.base_name = base_name
  if has_key(state, 'fetch_job') && job_status(state.fetch_job) == 'run'
    job_stop(state.fetch_job)
  endif
  state.fetch_seq += 1
  const seq = state.fetch_seq
  state.fetch_job = repo.FetchBase(root, state.relpath, base_name,
    (lines, eol) => {
      if bufs->get(bufnr, {}) is state && state.fetch_seq == seq
        state.base = lines
        state.eol = eol
        Update(bufnr)
      endif
    },
    () => {
      # Not at the base, e.g. untracked: no signs.
      if bufs->get(bufnr, {}) is state && state.fetch_seq == seq
        Detach(bufnr)
      endif
    })
enddef

# Diff after edits, at most every 100ms per buffer.
var timers: dict<number> = {}
def Schedule(bufnr: number)
  if !has_key(bufs, bufnr) || has_key(timers, bufnr)
    return
  endif
  timers[bufnr] = timer_start(100, (_) => {
    remove(timers, bufnr)
    Update(bufnr)
  })
enddef

def RefreshAll()
  for bufnr in keys(bufs)
    Refresh(str2nr(bufnr), true)
  endfor
enddef

# ---------------------------------------------------------------------------
# :Hunks
# ---------------------------------------------------------------------------

export def Toggle()
  enabled = !enabled
  for bufnr in keys(bufs)
    const state = bufs[bufnr]
    if enabled
      signs.Place(str2nr(bufnr), state.hunks)
    else
      signs.Clear(str2nr(bufnr))
    endif
  endfor
  echo $'hunks: signs {enabled ? "on" : "off"}'
enddef

# Each subcommand takes the arguments after its name and the command's
# range: Handler(args, line1, line2, has_range).
const COMMANDS: dict<func> = {
  toggle: (_, _, _, _) => {
    Toggle()
  },
  refresh: (_, _, _, _) => {
    Refresh(bufnr(), true)
  },
  next: (args, _, _, _) => {
    actions.Nav(true, str2nr(get(args, 0, '1')))
  },
  prev: (args, _, _, _) => {
    actions.Nav(false, str2nr(get(args, 0, '1')))
  },
  preview: (_, _, _, _) => {
    actions.Preview()
  },
  reset: (_, line1, line2, has_range) => {
    actions.Reset(line1, line2, has_range)
  },
  diffthis: (_, _, _, _) => {
    actions.DiffThis()
  },
}

export def Command(args: string, line1: number, line2: number, has_range: bool)
  const words = split(args)
  const name = get(words, 0, '')
  if !has_key(COMMANDS, name)
    echohl ErrorMsg
    echomsg $'hunks: unknown command "{name}", try one of: {keys(COMMANDS)->sort()->join(", ")}'
    echohl None
    return
  endif
  COMMANDS[name](words[1 :], line1, line2, has_range)
enddef

export def Complete(arg_lead: string, cmd_line: string, _: number): list<string>
  # Only the subcommand name is completed.
  if cmd_line =~ '^\S*Hunks\s\+\S\+\s'
    return []
  endif
  return keys(COMMANDS)->sort()->filter((_, c) => c =~ $'^{arg_lead}')
enddef

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

export def Setup()
  signs.Define()
  augroup hunks
    autocmd!
    autocmd BufReadPost,BufWritePost,BufFilePost * Refresh(str2nr(expand('<abuf>')))
    autocmd BufEnter,FocusGained,ShellCmdPost * Refresh(bufnr())
    # Catches a `git add` or commit made outside Vim.
    autocmd CursorHold * Refresh(bufnr(), false, false)
    autocmd TextChanged,TextChangedI,InsertLeave * Schedule(bufnr())
    autocmd BufWipeout * Detach(str2nr(expand('<abuf>')))
    # A `git init` from a shell can put a path in a repository.
    autocmd FocusGained,ShellCmdPost * repo.ForgetRoots()
    autocmd ColorScheme * signs.Highlights()
  augroup END
enddef
