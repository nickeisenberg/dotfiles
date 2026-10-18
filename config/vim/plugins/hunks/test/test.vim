vim9script

# Run by run.sh: vim -Nu NONE -es -S test.vim, with $HUNKS_TEST_DIFF the
# backend and $HUNKS_TEST_OUT the file to write the result to.
#
# Autocmds for edits (TextChanged) don't fire in -es mode, so the tests
# call hunks#Update() themselves where typing would.

const OUT = $HUNKS_TEST_OUT
const PLUGIN = expand('<sfile>:p:h:h')

g:hunks_diff = $HUNKS_TEST_DIFF
if g:hunks_diff == 'builtin' && !exists('*diff')
  writefile(['SKIP no diff() in this Vim'], OUT)
  qall!
endif

&runtimepath = $'{PLUGIN},{&runtimepath}'
runtime plugin/hunks.vim

import autoload 'hunks/signs.vim'
import autoload 'hunks/differ.vim'
import autoload 'hunks/actions.vim'
import autoload 'hunks/blame.vim'

const REPO = tempname()
mkdir(REPO, 'p')

def Git(...args: list<string>): string
  const out = system(['git', '-C', REPO, '-c', 'user.name=Test', '-c', 'user.email=test@example.com']
    ->extend(args)->map((_, a) => shellescape(a))->join())
  assert_equal(0, v:shell_error, $'git {join(args)}: {out}')
  return out
enddef

Git('init', '-q')

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

# After an edit: diff, and wait for the signs to match.
def Expect(expected: dict<string>, what: string)
  hunks#Update(bufnr())
  WaitFor(() => signs.Placed(bufnr()) == expected)
  assert_equal(expected, signs.Placed(bufnr()), what)
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
  WaitFor(() => signs.Placed(bufnr()) == {})
  assert_equal({}, signs.Placed(bufnr()), 'after git add')
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

def Test_toggle()
  Open('c.txt', ['1'])
  setline(1, 'x')
  Expect({'1': 'change'}, 'before toggle')
  Hunks toggle
  assert_equal({}, signs.Placed(bufnr()), 'toggled off')
  Hunks toggle
  assert_equal({'1': 'change'}, signs.Placed(bufnr()), 'toggled on')
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
  if !exists('*diff')
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
  WaitFor(() => signs.Placed(bufnr()) == expected)
  assert_equal(expected, signs.Placed(bufnr()), what)
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
  WaitFor(() => signs.Placed(bufnr()) == {'1': 'change', '3': 'change'})
  assert_equal({'1': 'change', '3': 'change'}, signs.Placed(bufnr()), 'against HEAD')
  Hunks stage
  assert_equal("one\n2\n3\n", Indexed('base.txt'), 'no staging against HEAD')

  Hunks base no-such-rev
  assert_equal('HEAD', g:hunks_base, 'a bad revision is refused')

  Hunks base index
  WaitFor(() => signs.Placed(bufnr()) == {'3': 'change'})
  assert_equal({'3': 'change'}, signs.Placed(bufnr()), 'back to the index')
  assert_equal(['index', 'HEAD'], hunks#Complete('', 'Hunks base ', 0), 'completion')
enddef

def Test_blame()
  Open('blame.txt', ['1', '2'])
  const state = hunks#Current(bufnr())
  const lines = blame.ForLine(state, 1)
  assert_match('^\x\{8}  Test  \d\{4}-\d\d-\d\d \d\d:\d\d$', lines[0], 'commit, author, date')
  assert_equal(['', 'add blame.txt'], lines[1 :], 'the message')
  setline(2, 'x')
  assert_equal(['Not committed yet'], blame.ForLine(state, 2), 'a changed line')
  Hunks blame
  popup_clear()
enddef

# ---------------------------------------------------------------------------

const TESTS = [
  Test_untracked_and_outside,
  Test_signs,
  Test_index_changes,
  Test_odd_names,
  Test_toggle,
  Test_parse_hunks,
  Test_backends_agree,
  Test_nav,
  Test_preview,
  Test_reset,
  Test_diffthis,
  Test_stage,
  Test_stage_line_endings,
  Test_base,
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
writefile(empty(failed) ? [$'OK {len(TESTS)} tests'] : failed, OUT)
qall!
