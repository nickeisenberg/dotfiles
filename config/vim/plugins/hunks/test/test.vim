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

const TESTS = [
  Test_untracked_and_outside,
  Test_signs,
  Test_index_changes,
  Test_odd_names,
  Test_toggle,
  Test_parse_hunks,
  Test_backends_agree,
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
