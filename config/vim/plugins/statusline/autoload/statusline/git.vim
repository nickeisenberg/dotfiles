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
# and the buffer is compared against it with diff() as you edit. A Vim
# without diff() (before 9.1.0071) counts from `git diff` instead, so the
# counts follow the saved file rather than the buffer.

# exists('*diff') isn't enough: a Vim built without the internal diff
# (Apple's /usr/bin/vim, no "internal" in 'diffopt') has diff() but it
# returns 0, so call it once and check for a list.
def DiffWorks(): bool
  try
    return exists('*diff')
      && type(call('diff', [['a'], ['b'], {output: 'indices'}])) == v:t_list
  catch
    return false
  endtry
enddef

const HAS_DIFF = DiffWorks()

# Called when a buffer's counts change, to redraw; set by Setup().
def Nothing()
enddef
var OnChange: func() = Nothing

# file path -> repository root, or '' outside a repository.
var roots: dict<string> = {}

# repository root -> its git directory.
var git_dirs: dict<string> = {}

# HEAD path -> {stamp: [mtime, size], branch: string}.
var heads: dict<dict<any>> = {}

# bufnr -> {path, stamp, base, eol, counts, job}: the resolved file path;
# the index's [mtime, size] when fetched, or [] to fetch again; the file's
# lines in the index and whether they end with a newline (base is null
# until fetched, and for a file not in the index); the last counts; the
# fetch.
var bufs: dict<dict<any>> = {}

# A file buffer's absolute path with symlinks resolved, so a file reached
# through a link to a repository is found in it; '' for special and
# unnamed buffers.
export def Path(bufnr: number): string
  const name = bufname(bufnr)
  if empty(name) || !empty(getbufvar(bufnr, '&buftype'))
    return ''
  endif
  return resolve(fnamemodify(name, ':p'))
enddef

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
  if !has_key(git_dirs, root)
    const dot_git = $'{root}/.git'
    var dir = ''
    if !isdirectory(dot_git) && filereadable(dot_git)
      dir = get(readfile(dot_git, '', 1), 0, '')->matchstr('^gitdir:\s*\zs.\{-}\ze\s*$')
    endif
    git_dirs[root] = empty(dir) ? dot_git : simplify(dir[0] == '/' ? dir : $'{root}/{dir}')
  endif
  return git_dirs[root]
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
  # File times are in whole seconds: a HEAD written this second may be
  # written again this second, so read it again next time.
  heads[head] = {stamp: localtime() <= stamp[0] ? [] : stamp, branch: branch}
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

# Count like gitsigns: a hunk that only adds or only removes lines counts
# them as such; one that replaces lines counts the overlap as changed and
# the rest as added or removed. A hunk is [old line count, new line count].
def Tally(hunks: list<list<number>>): dict<number>
  var counts = {added: 0, changed: 0, removed: 0}
  for [from, to] in hunks
    const changed = min([from, to])
    counts.changed += changed
    counts.added += to - changed
    counts.removed += from - changed
  endfor
  return counts
enddef

# The hunks of `git diff -U0` output: "@@ -a,b +c,d @@", counts default 1.
def ParseHunks(lines: list<string>): list<list<number>>
  var hunks: list<list<number>> = []
  for line in lines
    const m = matchlist(line, '^@@ -\d\+\%(,\(\d\+\)\)\= +\d\+\%(,\(\d\+\)\)\= @@')
    if !empty(m)
      hunks->add([empty(m[1]) ? 1 : str2nr(m[1]), empty(m[2]) ? 1 : str2nr(m[2])])
    endif
  endfor
  return hunks
enddef

def SetCounts(bufnr: number, counts: dict<number>)
  const state = bufs->get(bufnr, {})
  if !empty(state) && counts != state->get('counts', {})
    state.counts = counts
    OnChange()
  endif
enddef

def Recount(bufnr: number)
  const state = bufs->get(bufnr, {})
  if !HAS_DIFF || empty(state) || type(state.base) != v:t_list || !bufloaded(bufnr)
    return
  endif
  var base = state.base
  var lines = getbufline(bufnr, 1, '$')
  # An empty buffer still has one empty line.
  if lines == [''] && empty(base)
    lines = []
  endif
  # A missing newline at the end changes the last line, as git sees it. The
  # buffer is written with one when 'eol' is set, or 'fixeol' is (which
  # leaves 'eol' unset until the file is read again). A marker on the side
  # without one makes the last lines differ.
  const eol = getbufvar(bufnr, '&eol') || getbufvar(bufnr, '&fixeol') && !getbufvar(bufnr, '&binary')
  if eol != state.eol && !empty(base) && !empty(lines)
    if eol
      base = base[: -2] + [base[-1] .. "\x01"]
    else
      lines[-1] ..= "\x01"
    endif
  endif
  # Through call(), so a Vim without diff() can still compile this.
  const hunks = call('diff', [base, lines, {output: 'indices'}])
  SetCounts(bufnr, Tally(hunks->mapnew((_, h) => [h.from_count, h.to_count])))
enddef

# Changes when the index is written: by add, commit, checkout, reset.
def Stamp(root: string): list<number>
  const index = $'{GitDir(root)}/index'
  return [getftime(index), getfsize(index)]
enddef

# Fetch the file's version in the index, unless the index hasn't changed
# since the last fetch; then recount, if `recount`.
def Refresh(bufnr: number, force = false, recount = true)
  const path = Path(bufnr)
  const root = empty(path) ? '' : Root(path)
  if empty(root)
    if has_key(bufs, bufnr)
      remove(bufs, bufnr)
      OnChange()
    endif
    return
  endif

  const stamp = Stamp(root)
  var state = bufs->get(bufnr, {})
  if !force && !empty(state) && state.stamp == stamp && state.path == path
    if recount
      Recount(bufnr)
    endif
    return
  endif
  if !empty(state) && state->has_key('job') && job_status(state.job) == 'run'
    job_stop(state.job)
  endif

  # File times are in whole seconds: an index written this second may be
  # written again this second without changing the stamp, so leave it
  # unset and fetch again on the next check.
  state = {path: path, stamp: localtime() <= stamp[0] ? [] : stamp, base: null, eol: true,
           counts: state->get('counts', {})}
  bufs[bufnr] = state

  const relpath = $':./{strpart(path, len(root) + 1)}'
  const cmd = HAS_DIFF
    ? ['git', '--no-pager', 'show', relpath]
    : ['git', '--no-pager', 'diff', '--no-color', '--no-ext-diff', '-U0', '--', relpath]
  # Done when both the output has been read and the exit status is in;
  # either can come first.
  var chunks: list<string> = []
  var exitval = -1
  var closed = false
  const Done = () => {
    if closed && exitval >= 0
      Fetched(bufnr, state, join(chunks, ''), exitval)
    endif
  }
  state.job = job_start(cmd, {
    cwd: root,
    in_io: 'null',
    err_io: 'null',
    out_mode: 'raw',
    out_cb: (_, chunk) => {
      chunks->add(chunk)
    },
    close_cb: (_) => {
      closed = true
      Done()
    },
    exit_cb: (_, status) => {
      exitval = status
      Done()
    },
  })
enddef

def Fetched(bufnr: number, state: dict<any>, text: string, exitval: number)
  if bufs->get(bufnr, {}) isnot state
    return
  endif
  # Not in the index, e.g. untracked: no counts, and no new fetch until
  # the index changes.
  if exitval != 0
    SetCounts(bufnr, {})
    return
  endif
  var lines = empty(text) ? [] : split(text, "\n", true)
  state.eol = text =~ '\n$'
  if state.eol
    remove(lines, -1)
  endif
  if HAS_DIFF
    state.base = lines
    Recount(bufnr)
  else
    SetCounts(bufnr, Tally(ParseHunks(lines)))
  endif
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
  git_dirs = {}
enddef

# Start following buffers; Changed() is called when counts change.
export def Setup(Changed: func())
  OnChange = Changed
  augroup statusline_git
    autocmd!
    # A `git init` from a shell can put a path in a repository. Before the
    # Refresh below, so it sees the change.
    autocmd FocusGained,ShellCmdPost * ForgetRoots()
    # Counted from `git diff`, the counts follow the saved file: count
    # again. With diff(), the index's version is all that's needed.
    autocmd BufReadPost,BufWritePost,BufFilePost * Refresh(str2nr(expand('<abuf>')), !HAS_DIFF)
    autocmd BufEnter,FocusGained,ShellCmdPost * Refresh(bufnr())
    # Catches a `git add` or commit made outside Vim.
    autocmd CursorHold * Refresh(bufnr(), false, false)
    if HAS_DIFF
      autocmd TextChanged,TextChangedI,InsertLeave * Schedule(bufnr())
    endif
    autocmd BufWipeout * Forget(str2nr(expand('<abuf>')))
  augroup END
enddef
