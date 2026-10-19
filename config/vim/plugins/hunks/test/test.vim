vim9script

# Run by run.sh: vim -Nu NONE -es -S test.vim, with $HUNKS_TEST_DIFF the
# backend and $HUNKS_TEST_OUT the file to write the result to.
#
# Autocmds for edits (TextChanged) don't fire in -es mode, so the tests
# call hunks#Update() themselves where typing would.

const OUT = $HUNKS_TEST_OUT
const PLUGIN = expand('<sfile>:p:h:h')
# As in the plugin: Apple's /usr/bin/vim has a diff() that returns 0.
def DiffWorks(): bool
  try
    return exists('*diff')
      && type(call('diff', [['a'], ['b'], {output: 'indices'}])) == v:t_list
  catch
    return false
  endtry
enddef
const HAS_DIFF = DiffWorks()

g:hunks_diff = $HUNKS_TEST_DIFF
if g:hunks_diff == 'builtin' && !HAS_DIFF
  writefile(['SKIP no diff() in this Vim'], OUT)
  qall!
endif

&runtimepath = $'{PLUGIN},{&runtimepath}'
runtime plugin/hunks.vim

import autoload 'hunks/differ.vim'
import autoload 'hunks/actions.vim'
import autoload 'hunks/blame.vim'
import autoload 'hunks/repo.vim'

const REPO = tempname()
mkdir(REPO, 'p')

def Git(...args: list<string>): string
  const out = system(['git', '-C', REPO, '-c', 'user.name=Test', '-c', 'user.email=test@example.com']
    ->extend(args)->map((_, a) => shellescape(a))->join())
  assert_equal(0, v:shell_error, $'git {join(args)}: {out}')
  return out
enddef

Git('init', '-q')

# git, through a wrapper that can log its arguments ($HUNKS_TEST_GIT_LOG)
# and be slow ($HUNKS_TEST_GIT_SLEEP seconds) for the plugin's jobs.
const BIN = tempname()
mkdir(BIN, 'p')
writefile(['#!/bin/sh',
  '[ -n "$HUNKS_TEST_GIT_LOG" ] && echo "$*" >> "$HUNKS_TEST_GIT_LOG"',
  '[ -n "$HUNKS_TEST_GIT_SLEEP" ] && sleep "$HUNKS_TEST_GIT_SLEEP"',
  $'exec {shellescape(exepath("git"))} "$@"'], $'{BIN}/git')
setfperm($'{BIN}/git', 'rwx------')
$PATH = $'{BIN}:{$PATH}'

# Wait until Cond() is true, up to 3 seconds; jobs and timers run meanwhile.
def WaitFor(Cond: func(): bool): bool
  for _ in range(300)
    if Cond()
      return true
    endif
    sleep 10m
  endfor
  return Cond()
enddef

# Commit a file with `lines` and open it, ready to edit.
def Open(name: string, lines: list<string>)
  writefile(lines, $'{REPO}/{name}')
  Git('add', '--', name)
  Git('commit', '-q', '-m', $'add {name}')
  execute 'edit!' fnameescape($'{REPO}/{name}')
  assert_true(WaitFor(() => !empty(hunks#State(bufnr()))), $'{name} is tracked')
enddef

# The kinds of the signs placed in a buffer, by line: {lnum: kind}, the
# kind from the sign's name (HunksTopDelete: topdelete).
def Placed(bufnr: number): dict<string>
  var placed: dict<string> = {}
  for s in sign_getplaced(bufnr, {group: 'hunks'})[0].signs
    placed[string(s.lnum)] = tolower(s.name[5 :])
  endfor
  return placed
enddef

# After an edit: diff, and wait for the signs to match.
def Expect(expected: dict<string>, what: string)
  hunks#Update(bufnr())
  WaitFor(() => Placed(bufnr()) == expected)
  assert_equal(expected, Placed(bufnr()), what)
enddef

# ---------------------------------------------------------------------------
# Phase 1: signs
# ---------------------------------------------------------------------------

def Test_untracked_and_outside()
  writefile(['x'], $'{REPO}/untracked.txt')
  execute 'edit' fnameescape($'{REPO}/untracked.txt')
  sleep 300m
  assert_equal({}, hunks#State(bufnr()), 'untracked file')

  const outside = tempname()
  writefile(['x'], outside)
  execute 'edit' fnameescape(outside)
  sleep 100m
  assert_equal({}, hunks#State(bufnr()), 'file outside a repository')
enddef

# A file that isn't tracked: git isn't asked again on every BufEnter.
def Test_untracked_not_retried()
  writefile(['x'], $'{REPO}/untracked2.txt')
  execute 'edit' fnameescape($'{REPO}/untracked2.txt')
  # Past the second of the last index change, so the stamp is kept.
  sleep 1100m
  hunks#Refresh(bufnr())
  sleep 300m
  const log = tempname()
  $HUNKS_TEST_GIT_LOG = log
  doautocmd BufEnter
  doautocmd CursorHold
  hunks#Refresh(bufnr())
  sleep 300m
  $HUNKS_TEST_GIT_LOG = ''
  assert_equal([], filereadable(log) ? readfile(log) : [], 'no git run for an untracked file')
  Git('add', 'untracked2.txt')
  hunks#Refresh(bufnr())
  assert_true(WaitFor(() => !empty(hunks#State(bufnr()))), 'tried again after git add')
  Git('rm', '-q', '--cached', 'untracked2.txt')
enddef

# A `git init` and `git add` from :! show signs right away.
def Test_git_init_from_shell()
  const dir = tempname()
  mkdir(dir, 'p')
  writefile(['1', '2'], $'{dir}/f.txt')
  execute 'edit' fnameescape($'{dir}/f.txt')
  sleep 100m
  assert_equal({}, hunks#State(bufnr()), 'outside a repository')
  system($'git -C {shellescape(dir)} init -q && git -C {shellescape(dir)} add f.txt')
  doautocmd ShellCmdPost
  assert_true(WaitFor(() => !empty(hunks#State(bufnr()))), 'tracked after git init')
  setline(1, 'one')
  Expect({'1': 'change'}, 'signs after git init')
  delete(dir, 'rf')
enddef

# A `git init` in a directory between the file and its repository: the
# file now belongs to the nearer one.
def Test_nested_git_init()
  mkdir($'{REPO}/nested', 'p')
  Open('nested/n.txt', ['1', '2'])
  assert_equal(resolve(REPO), hunks#State(bufnr()).root, 'in the outer repository')
  const nested = $'{REPO}/nested'
  system($'git -C {shellescape(nested)} init -q && git -C {shellescape(nested)} add n.txt')
  doautocmd ShellCmdPost
  assert_true(WaitFor(() => hunks#State(bufnr())->get('root', '') == resolve(nested)),
    'in the nested repository')
  assert_equal('n.txt', hunks#State(bufnr()).relpath, 'the path in the nested repository')
  delete($'{nested}/.git', 'rf')
  repo.ForgetRoots()
enddef

def Test_signs()
  Open('a.txt', ['1', '2', '3', '4', '5'])
  Expect({}, 'unchanged')

  append(2, 'new')
  Expect({'3': 'add'}, 'added line')
  deletebufline('%', 3)

  setline(2, 'two')
  Expect({'2': 'change'}, 'changed line')
  setline(2, '2')

  deletebufline('%', 3)
  Expect({'2': 'delete'}, 'removed line')
  append(2, '3')

  deletebufline('%', 1)
  Expect({'1': 'topdelete'}, 'removed first line')
  append(0, '1')

  setline(2, 'two')
  deletebufline('%', 3)
  Expect({'2': 'changedelete'}, 'changed then removed')
  setline(2, '2')
  append(2, '3')

  setline(5, 'five')
  append(5, ['six', 'seven'])
  Expect({'5': 'change', '6': 'add', '7': 'add'}, 'changed then added at the end')
  deletebufline('%', 6, 7)
  setline(5, '5')
  Expect({}, 'back to unchanged')
enddef

def Test_index_changes()
  Open('b.txt', ['1', '2'])
  setline(1, 'one')
  write
  Expect({'1': 'change'}, 'before git add')
  Git('add', 'b.txt')
  # What a BufEnter or CursorHold does after a `git add` in a shell.
  hunks#Refresh(bufnr())
  WaitFor(() => Placed(bufnr()) == {})
  assert_equal({}, Placed(bufnr()), 'after git add')
enddef

def Test_odd_names()
  Open('with space.txt', ['a'])
  setline(1, 'b')
  Expect({'1': 'change'}, 'file name with a space')

  Open('empty.txt', [])
  Expect({}, 'empty file')
  setline(1, 'x')
  Expect({'1': 'add'}, 'first line of an empty file')
enddef

def Test_text_changed_in_popup()
  assert_true(exists('#hunks#TextChangedP'), 'signs follow while the completion menu is open')
enddef

def Test_toggle()
  Open('c.txt', ['1'])
  setline(1, 'x')
  Expect({'1': 'change'}, 'before toggle')
  Hunks toggle
  assert_equal({}, Placed(bufnr()), 'toggled off')
  Hunks toggle
  assert_equal({'1': 'change'}, Placed(bufnr()), 'toggled on')
enddef

def Test_parse_hunks()
  assert_equal([
    {old_start: 1, old_count: 0, new_start: 1, new_count: 1},
    {old_start: 0, old_count: 1, new_start: 0, new_count: 0},
    {old_start: 1, old_count: 1, new_start: 1, new_count: 2},
    {old_start: 0, old_count: 0, new_start: 0, new_count: 3},
  ], differ.ParseHunks([
    'diff --git a/x b/x',
    '@@ -1,0 +2 @@ a',
    '@@ -1 +0,0 @@',
    '@@ -2 +2,2 @@ a',
    '@@ -0,0 +1,3 @@',
  ]))
enddef

# Both backends give the same hunks: the check that keeps the swap honest.
def Test_backends_agree()
  if !HAS_DIFF
    return
  endif
  const base = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
  const cases = [
    [],
    ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
    ['x', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'y'],
    ['a', 'c', 'e', 'g'],
    ['a', 'B', 'C', 'd', 'e', 'F', 'g', 'h', 'i'],
    ['h', 'g', 'f', 'e', 'd', 'c', 'b', 'a'],
  ]
  for lines in cases
    var builtin: list<dict<number>> = []
    var job: list<dict<number>> = [{}]
    differ.BuiltinDiffer(0, base, lines, (h) => {
      builtin = h
    })
    differ.JobDiffer(0, base, lines, (h) => {
      job = h
    })
    WaitFor(() => job != [{}])
    assert_equal(builtin, job, $'backends on {string(lines)}')
  endfor
  differ.Forget(0)
enddef

# ---------------------------------------------------------------------------
# Phase 2: jump, preview, reset, diffthis
# ---------------------------------------------------------------------------

def Test_nav()
  Open('nav.txt', range(1, 10)->mapnew((_, n) => string(n)))
  setline(2, 'x')
  setline(5, 'x')
  setline(8, 'x')
  cursor(1, 1)
  Hunks next
  assert_equal(2, line('.'), 'next')
  Hunks next
  assert_equal(5, line('.'), 'next again')
  Hunks next
  Hunks next
  assert_equal(2, line('.'), 'next wraps around')
  Hunks next 2
  assert_equal(8, line('.'), 'next with a count')
  Hunks prev
  assert_equal(5, line('.'), 'prev')
  cursor(1, 1)
  Hunks prev
  assert_equal(8, line('.'), 'prev wraps around')
  set nowrapscan
  cursor(9, 1)
  Hunks next
  assert_equal(9, line('.'), "no wrapping without 'wrapscan'")
  set wrapscan
enddef

def Test_preview()
  Open('preview.txt', ['1', '2', '3', '4'])
  setline(2, 'two')
  append(2, 'new')
  deletebufline('%', 5)
  const state = hunks#Current(bufnr())
  assert_equal(['@@ -2,1 +2,2 @@', '-2', '+two', '+new'],
    actions.DiffLines(state, state.hunks[0]), 'changed and added')
  assert_equal(['@@ -4,1 +4,0 @@', '-4'],
    actions.DiffLines(state, state.hunks[1]), 'removed')

  cursor(2, 1)
  Hunks preview
  if exists('*popup_list')
    assert_equal(1, len(popup_list()), 'a popup is open')
  endif
  popup_clear()
enddef

def Test_reset()
  Open('reset.txt', ['1', '2', '3', '4', '5'])
  const base = getline(1, '$')
  setline(2, 'two')
  append(3, 'new')
  deletebufline('%', 6)
  const edited = getline(1, '$')

  # Setting 'undolevels' ends the undo step, as typing would.
  &undolevels = &undolevels
  cursor(2, 1)
  Hunks reset
  assert_equal(['1', '2', '3', 'new', '4'], getline(1, '$'), 'one hunk')
  undo
  assert_equal(edited, getline(1, '$'), 'u undoes the reset')

  &undolevels = &undolevels
  :%Hunks reset
  assert_equal(base, getline(1, '$'), 'every hunk in the range')
  Expect({}, 'no signs after the reset')

  deletebufline('%', 1)
  :%Hunks reset
  assert_equal(base, getline(1, '$'), 'removed first line')

  :%delete
  :%Hunks reset
  assert_equal(base, getline(1, '$'), 'every line removed')

  Open('reset-empty.txt', [])
  setline(1, ['a', 'b'])
  :%Hunks reset
  assert_equal([''], getline(1, '$'), 'lines added to an empty file')
enddef

def Test_diffthis()
  Open('diffthis.txt', ['1', '2', '3'])
  setline(2, 'two')
  const bufnr = bufnr()
  Hunks diffthis
  assert_equal(2, winnr('$'), 'a split')
  assert_equal(bufnr, bufnr(), 'back in the buffer')
  assert_true(&diff, 'diff mode in the buffer')
  wincmd h
  assert_equal(['1', '2', '3'], getline(1, '$'), 'the base on the left')
  assert_true(&diff, 'diff mode in the base')
  assert_false(&modifiable, 'the base is read-only')
  quit
  assert_equal(1, winnr('$'), 'split closed')
  assert_false(&diff, 'diff mode off after closing the base')

  Hunks diffthis
  Hunks diffthis
  assert_equal(2, winnr('$'), 'a second diffthis replaces the split')
  wincmd h
  assert_equal('hunks://index/diffthis.txt', bufname(), 'the base is named')
  quit
enddef

# ---------------------------------------------------------------------------
# Phase 3: stage, base, blame
# ---------------------------------------------------------------------------

# The file's content in the index, exactly.
def Indexed(name: string): string
  return Git('cat-file', '-p', $':{name}')
enddef

# After staging, wait for the base to be fetched again.
def ExpectAfterStage(expected: dict<string>, what: string)
  WaitFor(() => Placed(bufnr()) == expected)
  assert_equal(expected, Placed(bufnr()), what)
enddef

def Test_stage()
  Open('stage.txt', ['1', '2', '3', '4', '5'])
  setline(2, 'two')
  setline(4, 'four')
  cursor(2, 1)
  Hunks stage
  assert_equal("1\ntwo\n3\n4\n5\n", Indexed('stage.txt'), 'one hunk staged, unsaved')
  ExpectAfterStage({'4': 'change'}, 'the other hunk keeps its sign')

  Hunks undo_stage
  assert_equal("1\n2\n3\n4\n5\n", Indexed('stage.txt'), 'undo_stage')
  ExpectAfterStage({'2': 'change', '4': 'change'}, 'signs back after undo_stage')

  append(5, 'six')
  deletebufline('%', 1)
  :%Hunks stage
  assert_equal("two\n3\nfour\n5\nsix\n", Indexed('stage.txt'), 'every hunk in the range')
  ExpectAfterStage({}, 'no signs once all is staged')

  # Back to back, with no wait for the index to be read again: the second
  # stage must not use hunks from before the first, which moved lines.
  Open('twice.txt', ['1', '2', '3', '4', '5'])
  append(0, ['new1', 'new2'])
  setline(7, 'five')
  cursor(1, 1)
  Hunks stage
  cursor(7, 1)
  Hunks stage
  assert_equal("new1\nnew2\n1\n2\n3\n4\nfive\n", Indexed('twice.txt'), 'two stages back to back')

  # A name that is a glob: its own index entry, not 1.txt's.
  writefile(['one'], $'{REPO}/1.txt')
  writefile(['x'], $'{REPO}/[0-9].txt')
  Git('add', '--', '1.txt', ':(literal)[0-9].txt')
  Git('commit', '-q', '-m', 'glob')
  execute 'edit!' fnameescape($'{REPO}/[0-9].txt')
  WaitFor(() => !empty(hunks#State(bufnr())))
  setline(1, 'X')
  Hunks stage
  assert_equal("X\n", Indexed('[0-9].txt'), 'a glob name staged')
  Hunks undo_stage
  assert_equal("x\n", Indexed('[0-9].txt'), 'a glob name unstaged')
enddef

def Test_stage_errors()
  Open('lock.txt', ['1', '2'])
  setline(1, 'one')
  cursor(1, 1)
  # update-index fails while the index is locked: its error is shown.
  const lock = $'{REPO}/.git/index.lock'
  writefile([], lock)
  var msg = execute('Hunks stage')
  assert_match('update-index failed: .*index.lock', msg, "update-index's error")
  delete(lock)
  Hunks stage
  assert_equal("one\n2\n", Indexed('lock.txt'), 'staged')

  # A failed undo_stage can be tried again.
  writefile([], lock)
  msg = execute('Hunks undo_stage')
  assert_match('update-index failed', msg, 'undo_stage fails while locked')
  delete(lock)
  Hunks undo_stage
  assert_equal("1\n2\n", Indexed('lock.txt'), 'undo_stage after a failed one')

  # After a `git add` of the file, undo_stage doesn't undo it.
  Hunks stage
  setline(2, 'two')
  write
  Git('add', 'lock.txt')
  hunks#Refresh(bufnr())
  msg = execute('Hunks undo_stage')
  assert_match('has changed since', msg, 'undo_stage refused after git add')
  assert_equal("one\ntwo\n", Indexed('lock.txt'), 'git add kept')

  # Nor after a commit.
  setline(2, 'TWO')
  cursor(2, 1)
  Hunks stage
  Git('commit', '-q', '-m', 'lock')
  hunks#Refresh(bufnr())
  msg = execute('Hunks undo_stage')
  assert_match('has changed since', msg, 'undo_stage refused after a commit')
  assert_equal("one\nTWO\n", Indexed('lock.txt'), 'commit kept')

  const result = repo.Git(REPO, ['rev-parse', '--verify', 'no-such-rev'])
  assert_equal([false, ''], [result.ok, result.output], 'a failed git, no stdout')
  assert_notequal('', result.error, 'its stderr apart')
enddef

def Test_stage_line_endings()
  # No newline at the end: staging a hunk elsewhere keeps it that way.
  writefile(['1', '2'], $'{REPO}/noeol.txt', 'b')
  Git('add', 'noeol.txt')
  Git('commit', '-q', '-m', 'noeol')
  execute 'edit!' fnameescape($'{REPO}/noeol.txt')
  WaitFor(() => !empty(hunks#State(bufnr())))
  setline(1, 'one')
  cursor(1, 1)
  Hunks stage
  assert_equal("one\n2", Indexed('noeol.txt'), 'no newline at the end kept')

  # CRLF stored as is: no signs for unchanged lines, CRs kept when staged.
  writefile(["a\r", "b\r"], $'{REPO}/crlf.txt')
  Git('add', 'crlf.txt')
  Git('commit', '-q', '-m', 'crlf')
  execute 'edit!' fnameescape($'{REPO}/crlf.txt')
  assert_equal('dos', &fileformat, 'read as dos')
  WaitFor(() => !empty(hunks#State(bufnr())))
  Expect({}, 'CRLF file unchanged')
  setline(1, 'x')
  Expect({'1': 'change'}, 'CRLF file changed')
  cursor(1, 1)
  Hunks stage
  assert_equal("x\r\nb\r\n", Indexed('crlf.txt'), 'CRLF staged')
enddef

def Test_base()
  Open('base.txt', ['1', '2', '3'])
  setline(1, 'one')
  write
  Git('add', 'base.txt')
  hunks#Refresh(bufnr())
  setline(3, 'three')
  Expect({'3': 'change'}, 'against the index')

  Hunks base HEAD
  WaitFor(() => Placed(bufnr()) == {'1': 'change', '3': 'change'})
  assert_equal({'1': 'change', '3': 'change'}, Placed(bufnr()), 'against HEAD')
  Hunks stage
  assert_equal("one\n2\n3\n", Indexed('base.txt'), 'no staging against HEAD')

  Hunks base no-such-rev
  assert_equal('HEAD', g:hunks_base, 'a bad revision is refused')

  Hunks base index
  WaitFor(() => Placed(bufnr()) == {'3': 'change'})
  assert_equal({'3': 'change'}, Placed(bufnr()), 'back to the index')

  # Switching to the index and staging at once: the hunks are the index's,
  # whose lines are one down from HEAD's.
  Open('switch.txt', ['1', '2', '3'])
  setline(1, ['0', '1'])
  append(2, '2')
  write
  Git('add', 'switch.txt')
  setline(4, 'three')
  Hunks base HEAD
  WaitFor(() => hunks#State(bufnr()).base == ['1', '2', '3'])
  Hunks base index
  cursor(4, 1)
  Hunks stage
  assert_equal("0\n1\n2\nthree\n", Indexed('switch.txt'), 'staged right after :Hunks base index')
  assert_equal(['index', 'HEAD'], hunks#Complete('', 'Hunks base ', 0), 'completion')
  assert_equal(['index', 'HEAD'], hunks#Complete('', 'Hun base ', 0), 'completion, abbreviated')
  assert_equal(['stage'], hunks#Complete('st', "'<,'>Hunks st", 0), 'completion with a range')
  assert_equal([], hunks#Complete('', 'Hunks stage ', 0), 'no arguments to complete')

  # A revision that is also a tag: git warns, and the base is still read.
  Git('tag', 'twice')
  Git('branch', 'twice')
  Hunks base twice
  assert_true(WaitFor(() => hunks#State(bufnr())->get('base_name', '') == 'twice'), 'an ambiguous name')
  Hunks base index
enddef

# :Hunks base from a buffer outside any repository checks the tracked
# buffers' repositories.
def Test_base_elsewhere()
  Open('elsewhere.txt', ['1'])
  const tracked = bufnr()
  const other = tempname()
  mkdir(other, 'p')
  system($'git -C {shellescape(other)} init -q && cd {shellescape(other)} && echo x > o.txt && git add o.txt')
  execute 'edit' fnameescape($'{other}/o.txt')
  assert_true(WaitFor(() => !empty(hunks#State(bufnr()))), 'a buffer in another repository')
  enew
  Hunks base no-such-rev
  assert_equal('index', hunks#BaseName(), 'refused from a buffer outside a repository')
  # HEAD is in REPO, not in the other repository, which has no commits.
  const msg = execute('Hunks base HEAD')
  assert_equal('HEAD', hunks#BaseName(), 'taken when a repository has it')
  assert_match('lacks', msg, 'a warning for the one that lacks it')
  execute $'buffer {tracked}'
  assert_true(WaitFor(() => hunks#State(tracked)->get('base_name', '') == 'HEAD'), 'tracked against HEAD')
  Hunks base index
  delete(other, 'rf')
enddef

# A command while git is slow says so, not that the file isn't tracked.
def Test_slow_git()
  Open('slow.txt', ['1'])
  $HUNKS_TEST_GIT_SLEEP = '2'
  Hunks refresh
  $HUNKS_TEST_GIT_SLEEP = ''
  const msg = execute('Hunks next')
  assert_match("hasn't answered yet", msg, 'while the base is fetched')
  assert_true(WaitFor(() => !hunks#State(bufnr()).fetching), 'fetched in the end')
enddef

def Test_blame()
  Open('blame.txt', ['1', '2'])
  const state = hunks#Current(bufnr())
  const lines = blame.ForLine(state, 1)
  assert_match('^\x\{8}  Test  \d\{4}-\d\d-\d\d \d\d:\d\d$', lines[0], 'commit, author, date')
  assert_equal(['', 'add blame.txt'], lines[1 :], 'the message')
  setline(2, 'x')
  assert_equal(['Not committed yet'], blame.ForLine(state, 2), 'a changed line')

  writefile(["a\r", "b\r"], $'{REPO}/blame_crlf.txt')
  Git('add', 'blame_crlf.txt')
  Git('commit', '-q', '-m', 'add blame_crlf.txt')
  execute 'edit!' fnameescape($'{REPO}/blame_crlf.txt')
  assert_equal('dos', &fileformat, 'read as dos')
  assert_equal(['', 'add blame_crlf.txt'], blame.ForLine(hunks#Current(bufnr()), 1)[1 :], 'a CRLF file')

  writefile(['a', 'b'], $'{REPO}/blame_noeol.txt', 'b')
  Git('add', 'blame_noeol.txt')
  Git('commit', '-q', '-m', 'add blame_noeol.txt')
  execute 'edit!' fnameescape($'{REPO}/blame_noeol.txt')
  assert_equal(['', 'add blame_noeol.txt'], blame.ForLine(hunks#Current(bufnr()), 2)[1 :], 'the last line, no newline')
  execute 'edit!' fnameescape($'{REPO}/blame.txt')
  Hunks blame
  popup_clear()
enddef

# ---------------------------------------------------------------------------

const TESTS = [
  Test_untracked_and_outside,
  Test_untracked_not_retried,
  Test_git_init_from_shell,
  Test_nested_git_init,
  Test_signs,
  Test_index_changes,
  Test_odd_names,
  Test_text_changed_in_popup,
  Test_toggle,
  Test_parse_hunks,
  Test_backends_agree,
  Test_nav,
  Test_preview,
  Test_reset,
  Test_diffthis,
  Test_stage,
  Test_stage_errors,
  Test_stage_line_endings,
  Test_base,
  Test_base_elsewhere,
  Test_slow_git,
  Test_blame,
]
var failed: list<string> = []
for T in TESTS
  v:errors = []
  try
    T()
  catch
    v:errors->add($'{v:exception} at {v:throwpoint}')
  endtry
  if !empty(v:errors)
    failed->add(matchstr(get(T, 'name'), 'Test_.*'))->extend(v:errors->mapnew((_, e) => $'  {e}'))
  endif
  silent! :%bwipeout!
endfor

delete(REPO, 'rf')
delete(BIN, 'rf')
writefile(empty(failed) ? [$'OK {len(TESTS)} tests'] : failed, OUT)
qall!
