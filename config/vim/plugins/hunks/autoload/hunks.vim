vim9script

# Per-buffer state and the autocmds that keep it current: the file's text at
# the base (fetched again when the index or HEAD moves), and the hunks
# between that and the buffer (computed again as you edit).

import autoload './hunks/repo.vim'
import autoload './hunks/differ.vim'
import autoload './hunks/signs.vim'
import autoload './hunks/actions.vim'
import autoload './hunks/stage.vim'
import autoload './hunks/blame.vim'
import autoload './hunks/util.vim'

# bufnr -> {
#   path, root, relpath      the file, its repository, its path in there
#   stamp, base_name         when the base was fetched, and at what base
#   base, eol, crlf          the base's lines (without CRs), whether it ends
#                            with a newline, and whether its lines end with
#                            CRLF; missing until fetched
#   hunks                    from the last diff
#   tick                     the changedtick `hunks` are for; -1 after a
#                            fetch, until diffed against the new base
#   diff_tick                the changedtick last diffed, done or not
#   fetch_seq, fetch_job     the latest fetch; an older one is ignored
#   fetching                 while a fetch is running, so the commands wait
#                            for it rather than act on the old base
# }
var bufs: dict<dict<any>> = {}

# bufnr -> {path, stamp, base_name} of a fetch that failed (a file that
# isn't tracked, or not at that base), so it isn't tried again until one of
# them changes.
var failed: dict<dict<any>> = {}

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
  if has_key(failed, bufnr)
    remove(failed, bufnr)
  endif
  signs.Clear(bufnr)
  differ.Forget(bufnr)
enddef

# Diff the buffer against its base and place the signs. Skipped while the
# base is still being fetched.
export def Update(bufnr: number)
  const state = State(bufnr)
  if empty(state) || !bufloaded(bufnr)
    return
  endif
  const tick = getbufvar(bufnr, 'changedtick')
  state.diff_tick = tick
  differ.Hunks(bufnr, state.base, util.Lines(bufnr, state.base), (hunks) => {
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
# while the base is fetched). {} when the buffer isn't tracked, or the wait
# runs out.
export def Current(bufnr: number): dict<any>
  for _ in range(200)
    if !has_key(bufs, bufnr)
      return {}
    endif
    const state = State(bufnr)
    const tick = getbufvar(bufnr, 'changedtick')
    if !empty(state) && !state.fetching
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

# The current buffer's state for a command, as Current(), or {} after a
# warning.
def Tracked(): dict<any>
  const bufnr = bufnr()
  const state = Current(bufnr)
  if empty(state)
    util.Warn(has_key(bufs, bufnr)
      ? "git hasn't answered yet, try again in a moment"
      : 'this buffer is not tracked by git')
  endif
  return state
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
  if !force && failed->get(bufnr, {}) == {path: path, stamp: stamp, base_name: base_name}
    return
  endif
  var state = bufs->get(bufnr, {})
  if !force && !empty(state) && state.path == path && state.root == root
      && state.stamp == stamp && state.base_name == base_name
    if diff_anyway
      Update(bufnr)
    endif
    return
  endif

  # A new state for another file, or the same one in another repository
  # (after a `git init` in a directory above it).
  if empty(state) || state.path != path || state.root != root
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
  state.fetching = true
  state.fetch_job = repo.FetchBase(root, state.relpath, base_name,
    (lines, eol) => {
      if bufs->get(bufnr, {}) is state && state.fetch_seq == seq
        # A CRLF file stored as is: a 'fileformat' dos buffer has no CRs.
        state.crlf = getbufvar(bufnr, '&fileformat') == 'dos'
          && !empty(lines) && lines[0] =~ '\r$'
        state.base = state.crlf ? lines->map((_, l) => substitute(l, '\r$', '', '')) : lines
        state.eol = eol
        state.fetching = false
        # The hunks are for the old base until diffed again.
        state.tick = -1
        Update(bufnr)
      endif
    },
    () => {
      # Not at the base, e.g. untracked: no signs.
      if bufs->get(bufnr, {}) is state && state.fetch_seq == seq
        Detach(bufnr)
        failed[bufnr] = {path: path, stamp: state.stamp, base_name: base_name}
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

# Compare every buffer against `name` from now on: 'index', or a revision
# such as HEAD or main~2. Without a name, show the current one. A revision
# is looked up in the repositories of the current buffer and the tracked
# ones: refused when none has it, else a warning names those that don't
# (their buffers get no signs).
export def SetBase(name: string)
  if empty(name)
    echo $'hunks: the base is {BaseName()}'
    return
  endif
  var missing: list<string> = []
  if name != 'index'
    const path = Path(bufnr())
    var roots = values(bufs)->mapnew((_, s) => s.root)
    roots->add(empty(path) ? '' : repo.Root(path))
    roots = roots->filter((_, r) => !empty(r))->sort()->uniq()
    missing = roots->copy()->filter((_, r) =>
      !repo.Git(r, ['rev-parse', '--verify', '--quiet', $'{name}^{{commit}}']).ok)
    if !empty(roots) && missing == roots
      util.Warn($'no such revision: {name}')
      return
    endif
  endif
  g:hunks_base = name
  RefreshAll()
  if empty(missing)
    echo $'hunks: the base is {name}'
  else
    util.Warn($'the base is {name}, which {join(missing, ", ")} lacks: no signs there')
  endif
enddef

# Each subcommand takes the current buffer's state, the arguments after its
# name and the command's range: Handler(state, args, line1, line2,
# has_range). Without a range, line1 and line2 are the cursor line.
const COMMANDS: dict<func> = {
  toggle: (_, _, _, _, _) => {
    Toggle()
  },
  refresh: (_, _, _, _, _) => {
    Refresh(bufnr(), true)
  },
  next: (state, args, _, _, _) => {
    actions.Nav(state, true, str2nr(get(args, 0, '1')))
  },
  prev: (state, args, _, _, _) => {
    actions.Nav(state, false, str2nr(get(args, 0, '1')))
  },
  preview: (state, _, _, _, _) => {
    actions.Preview(state)
  },
  reset: (state, _, line1, line2, has_range) => {
    if actions.Reset(state, line1, line2, has_range)
      Update(bufnr())
    endif
  },
  diffthis: (state, _, _, _, _) => {
    actions.DiffThis(state)
  },
  stage: (state, _, line1, line2, has_range) => {
    if stage.Stage(state, line1, line2, has_range)
      Refresh(bufnr(), true)
    endif
  },
  undo_stage: (state, _, _, _, _) => {
    if stage.UndoStage(state)
      Refresh(bufnr(), true)
    endif
  },
  blame: (state, _, _, _, _) => {
    blame.Blame(state)
  },
  base: (_, args, _, _, _) => {
    SetBase(get(args, 0, ''))
  },
}

# The subcommands that work on the buffer's hunks: they get its state, and
# don't run when it isn't tracked. The others get {}.
const ON_HUNKS = ['next', 'prev', 'preview', 'reset', 'diffthis', 'stage', 'undo_stage', 'blame']

export def Command(args: string, line1: number, line2: number, has_range: bool)
  const words = split(args)
  const name = get(words, 0, '')
  if !has_key(COMMANDS, name)
    util.Warn($'unknown command "{name}", try one of: {keys(COMMANDS)->sort()->join(", ")}')
    return
  endif
  var state: dict<any> = {}
  if index(ON_HUNKS, name) >= 0
    state = Tracked()
    if empty(state)
      return
    endif
  endif
  COMMANDS[name](state, words[1 :], line1, line2, has_range)
enddef

export def Complete(arg_lead: string, cmd_line: string, _: number): list<string>
  # The words before the one being completed, after the command's name,
  # which may be abbreviated (:Hun) and have a range.
  var words = cmd_line->substitute('^[[:space:]:]*\S*', '', '')->split()
  if !empty(arg_lead)
    words = words[: -2]
  endif
  var choices: list<string> = []
  if empty(words)
    choices = keys(COMMANDS)->sort()
  elseif words == ['base']
    choices = ['index', 'HEAD']
  endif
  return choices->filter((_, c) => stridx(c, arg_lead) == 0)
enddef

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

export def Setup()
  signs.Define()
  augroup hunks
    autocmd!
    # A `git init` from a shell can put a path in a repository: forget the
    # roots before the Refresh below, which runs after this.
    autocmd FocusGained,ShellCmdPost * repo.ForgetRoots()
    autocmd BufReadPost,BufWritePost,BufFilePost * Refresh(str2nr(expand('<abuf>')))
    autocmd BufEnter,FocusGained,ShellCmdPost * Refresh(bufnr())
    # Catches a `git add` or commit made outside Vim.
    autocmd CursorHold * Refresh(bufnr(), false, false)
    autocmd TextChanged,TextChangedI,TextChangedP,InsertLeave * Schedule(bufnr())
    autocmd BufWipeout * Detach(str2nr(expand('<abuf>')))
    autocmd ColorScheme * signs.Highlights()
  augroup END
enddef
