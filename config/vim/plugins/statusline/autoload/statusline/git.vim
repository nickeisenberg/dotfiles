vim9script

# The repository a buffer belongs to, its current branch, and how the
# buffer differs from the git index.
#
# The branch is read straight from the repository's HEAD file instead of
# running git: one small read, redone only when HEAD changes, so the
# statusline follows a checkout made anywhere.
#
# Changed lines are counted the way gitsigns counts them: the file's
# version in the index is fetched once (and again when the index changes),
# and the buffer is compared against it with diff() as you edit.

# file path -> repository root, or '' outside a repository.
var roots: dict<string> = {}

# HEAD path -> {stamp: [mtime, size], branch: string}.
var heads: dict<dict<any>> = {}

# bufnr -> {base: list<string>, index_time: number, counts: dict, job: job}
var bufs: dict<dict<any>> = {}

export def Root(path: string): string
  if !has_key(roots, path)
    const dir = escape(fnamemodify(path, ':h'), ' ,;*?')
    # .git is a directory in a normal repository, and a file in worktrees
    # and submodules. The nearer one wins.
    var found_dir = finddir('.git', $'{dir};')
    var found_file = findfile('.git', $'{dir};')
    found_dir = empty(found_dir) ? '' : fnamemodify(found_dir, ':p:h:h')
    found_file = empty(found_file) ? '' : fnamemodify(found_file, ':p:h')
    roots[path] = len(found_dir) >= len(found_file) ? found_dir : found_file
  endif
  return roots[path]
enddef

# The git directory for a root: .git itself, or where a .git file
# ("gitdir: <path>") points.
def GitDir(root: string): string
  const dot_git = $'{root}/.git'
  if isdirectory(dot_git) || !filereadable(dot_git)
    return dot_git
  endif
  const dir = get(readfile(dot_git, '', 1), 0, '')->matchstr('^gitdir:\s*\zs.\{-}\ze\s*$')
  if empty(dir)
    return dot_git
  endif
  return simplify(dir[0] == '/' ? dir : $'{root}/{dir}')
enddef

# The branch name, a short hash when detached, or ''.
export def Branch(root: string): string
  const head = $'{GitDir(root)}/HEAD'
  const stamp = [getftime(head), getfsize(head)]
  if stamp[0] < 0
    return ''
  endif

  const hit = heads->get(head, {})
  if !empty(hit) && hit.stamp == stamp
    return hit.branch
  endif

  const line = get(readfile(head, '', 1), 0, '')
  var branch = matchstr(line, '^ref: refs/heads/\zs.\+$')
  if empty(branch)
    branch = matchstr(line, '^ref: \zs.\+$')
  endif
  if empty(branch)
    branch = line[: 6]
  endif
  heads[head] = {stamp: stamp, branch: branch}
  return branch
enddef

# ---------------------------------------------------------------------------
# Changed lines
# ---------------------------------------------------------------------------

# {added, changed, removed} for a buffer, or {} when it isn't tracked.
export def Counts(bufnr: number): dict<number>
  const state = bufs->get(bufnr, {})
  return state->get('counts', {})
enddef

def Path(bufnr: number): string
  const name = bufname(bufnr)
  if empty(name) || !empty(getbufvar(bufnr, '&buftype'))
    return ''
  endif
  return fnamemodify(name, ':p')
enddef

# Count like gitsigns: a hunk that only adds or only removes lines counts
# them as such; one that replaces lines counts the overlap as changed and
# the rest as added or removed.
def Recount(bufnr: number)
  const state = bufs->get(bufnr, {})
  if empty(state) || type(state.base) != v:t_list || !bufloaded(bufnr)
    return
  endif
  var counts = {added: 0, changed: 0, removed: 0}
  for hunk in diff(state.base, getbufline(bufnr, 1, '$'), {output: 'indices'})
    const changed = min([hunk.from_count, hunk.to_count])
    counts.changed += changed
    counts.added += hunk.to_count - changed
    counts.removed += hunk.from_count - changed
  endfor
  if counts != state->get('counts', {})
    state.counts = counts
    statusline#Redraw()
  endif
enddef

def IndexTime(root: string): number
  return getftime($'{GitDir(root)}/index')
enddef

# Fetch the file's version in the index, unless the index hasn't changed
# since the last fetch; then recount, if `recount`.
def Refresh(bufnr: number, force = false, recount = true)
  const path = Path(bufnr)
  const root = empty(path) ? '' : Root(path)
  if empty(root)
    if has_key(bufs, bufnr)
      remove(bufs, bufnr)
      statusline#Redraw()
    endif
    return
  endif

  const index_time = IndexTime(root)
  var state = bufs->get(bufnr, {})
  if !force && !empty(state) && state.index_time == index_time && state.path == path
    if recount
      Recount(bufnr)
    endif
    return
  endif
  if !empty(state) && state->has_key('job') && job_status(state.job) == 'run'
    job_stop(state.job)
  endif

  state = {path: path, index_time: index_time, base: null, counts: state->get('counts', {})}
  bufs[bufnr] = state

  var lines: list<string> = []
  state.job = job_start(['git', '--no-pager', 'show', $':./{strpart(path, len(root) + 1)}'], {
    cwd: root,
    in_io: 'null',
    err_io: 'null',
    out_mode: 'nl',
    out_cb: (_, line) => {
      lines->add(line)
    },
    close_cb: (_) => {
      # Wait for the exit status: not in the index means untracked.
      timer_start(0, (_) => Fetched(bufnr, state, lines))
    },
  })
enddef

def Fetched(bufnr: number, state: dict<any>, lines: list<string>)
  if bufs->get(bufnr, {}) isnot state
    return
  endif
  var tries = 0
  while job_status(state.job) == 'run' && tries < 100
    sleep 5m
    tries += 1
  endwhile
  if job_info(state.job).exitval != 0
    remove(bufs, bufnr)
    statusline#Redraw()
    return
  endif
  state.base = lines
  Recount(bufnr)
enddef

# Recount after edits, at most every 100ms per buffer.
var timers: dict<number> = {}
def Schedule(bufnr: number)
  if !has_key(bufs, bufnr) || has_key(timers, bufnr)
    return
  endif
  timers[bufnr] = timer_start(100, (_) => {
    remove(timers, bufnr)
    Recount(bufnr)
  })
enddef

def Forget(bufnr: number)
  if has_key(bufs, bufnr)
    remove(bufs, bufnr)
  endif
enddef

def ForgetRoots()
  roots = {}
enddef

export def Setup()
  augroup statusline_git
    autocmd!
    autocmd BufReadPost,BufWritePost,BufFilePost * Refresh(str2nr(expand('<abuf>')), true)
    autocmd BufEnter,FocusGained,ShellCmdPost * Refresh(bufnr())
    # Catches a `git add` or commit made outside Vim.
    autocmd CursorHold * Refresh(bufnr(), false, false)
    autocmd TextChanged,TextChangedI,InsertLeave * Schedule(bufnr())
    autocmd BufWipeout * Forget(str2nr(expand('<abuf>')))
    # A `git init` from a shell can put a path in a repository.
    autocmd FocusGained,ShellCmdPost * ForgetRoots()
  augroup END
enddef
