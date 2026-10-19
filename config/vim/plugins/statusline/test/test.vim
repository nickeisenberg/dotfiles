vim9script

# Run by run.sh: vim -Nu NONE -es -S test.vim, with $STATUSLINE_TEST_OUT
# the file to write the result to.
#
# Edits are saved, so the counts are the same with and without diff().
# Autocmds for edits don't fire in -es mode; the tests fire TextChanged.

const OUT = $STATUSLINE_TEST_OUT
const PLUGIN = expand('<sfile>:p:h:h')

&runtimepath = $'{PLUGIN},{&runtimepath}'
runtime plugin/statusline.vim

import autoload 'statusline/git.vim'

const TMP = tempname()
const REPO = $'{TMP}/repo'
mkdir(REPO, 'p')

# A git that logs its arguments, to count fetches.
const LOG = $'{TMP}/git.log'
mkdir($'{TMP}/bin')
writefile(['#!/bin/sh', $'echo "$*" >> {LOG}', $'exec {exepath("git")} "$@"'], $'{TMP}/bin/git')
setfperm($'{TMP}/bin/git', 'rwxr-xr-x')
$PATH = $'{TMP}/bin:{$PATH}'

def Fetches(): number
  return filereadable(LOG) ? len(readfile(LOG)) : 0
enddef

def Git(...args: list<string>)
  const out = system(['git', '-C', REPO, '-c', 'user.name=Test', '-c', 'user.email=test@example.com']
    ->extend(args)->map((_, a) => shellescape(a))->join())
  assert_equal(0, v:shell_error, $'git {join(args)}: {out}')
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

def Expect(expected: dict<number>, what: string)
  doautocmd TextChanged
  if !WaitFor(() => git.Counts(bufnr()) == expected)
    assert_equal(expected, git.Counts(bufnr()), what)
  endif
enddef

# Commit a file with `lines` (written as is, so a last line without a
# newline stays so) and open it.
def Open(name: string, lines: list<string>, flags = '')
  writefile(lines, $'{REPO}/{name}', flags)
  Git('add', '--', name)
  Git('commit', '-q', '-m', $'add {name}')
  execute 'edit!' fnameescape($'{REPO}/{name}')
enddef

const NONE = {added: 0, changed: 0, removed: 0}

def Test_counts()
  Open('a.txt', ['1', '2', '3'])
  Expect(NONE, 'unchanged')
  setline(2, 'two')
  append(3, ['4', '5'])
  silent write
  Expect({added: 2, changed: 1, removed: 0}, 'edited')
  :1delete
  silent write
  Expect({added: 2, changed: 1, removed: 1}, 'line removed')
enddef

def Test_empty_file()
  Open('empty.txt', [])
  Expect(NONE, 'empty tracked file')
enddef

def Test_untracked()
  writefile(['x'], $'{REPO}/untracked.txt')
  execute 'edit' fnameescape($'{REPO}/untracked.txt')
  # `git diff` finds no changes in an untracked file; nothing is shown
  # either way.
  const untracked = exists('*diff') ? {} : NONE
  Expect(untracked, 'untracked')
  # A second past the index's last change, so the failure is remembered.
  sleep 1100m
  doautocmd BufEnter
  sleep 200m
  const before = Fetches()
  doautocmd BufEnter
  doautocmd CursorHold
  sleep 200m
  assert_equal(before, Fetches(), 'no new fetch for an untracked file')
  Expect(untracked, 'still untracked')
enddef

# Like ~/.vim linked to a directory in a dotfiles repository: the link
# itself is outside it.
def Test_symlink()
  const link = $'{TMP}/link'
  mkdir($'{REPO}/sub')
  system($'ln -s {shellescape($"{REPO}/sub")} {shellescape(link)}')
  Open('sub/linked.txt', ['1'])
  # Else Vim finds the same file open already, under its real name.
  bwipeout!
  execute 'edit' fnameescape($'{link}/linked.txt')
  assert_equal($'{link}/linked.txt', expand('%:p'))
  setline(1, 'one')
  silent write
  Expect({added: 0, changed: 1, removed: 0}, 'through a symlink')
  assert_match('sub/linked.txt', statusline#Render())
  assert_match('StlGit', statusline#Render(), 'branch through a symlink')
enddef

def Test_same_second()
  Open('fast.txt', ['1', '2'])
  Expect(NONE, 'opened')
  setline(1, 'x')
  silent write
  Git('add', '--', 'fast.txt')
  doautocmd CursorHold
  Expect(NONE, 'staged')
  # Staged again in the same second: the index keeps its time and size.
  setline(1, 'y')
  silent write
  Git('add', '--', 'fast.txt')
  doautocmd CursorHold
  Expect(NONE, 'staged again in the same second')
enddef

def Test_eol()
  Open('noeol.txt', ['1', '2'], 'b')
  assert_false(&eol)
  # 'fixeol' adds the newline when written.
  Expect(exists('*diff') ? {added: 0, changed: 1, removed: 0} : NONE, 'before the write')
  silent write
  assert_false(&eol, "'eol' stays unset after the write")
  Expect({added: 0, changed: 1, removed: 0}, 'newline added')
  set nofixeol
  silent write
  Expect(NONE, 'newline left out again')
  set fixeol&
enddef

def Test_no_fetch_on_write()
  if !exists('*diff')
    return
  endif
  Open('write.txt', ['1'])
  Expect(NONE, 'opened')
  sleep 1100m
  doautocmd BufEnter
  sleep 200m
  const before = Fetches()
  setline(1, 'x')
  silent write
  Expect({added: 0, changed: 1, removed: 0}, 'edited')
  assert_equal(before, Fetches(), 'no fetch on write')
enddef

def Test_highlights()
  # Vim 9.0 has no Added group; the counts are colored all the same.
  for name in ['StlAdded', 'StlChanged', 'StlRemoved']
    const group = hlget(name)[0]
    assert_true(has_key(group, 'ctermfg') || has_key(group, 'ctermbg'), $'{name}: {string(group)}')
  endfor
  # The default StatusLine is reverse, and so are the groups on it.
  assert_true(hlget('StlError')[0]->get('cterm', {})->get('reverse', false), 'reverse')
enddef

const TESTS = [
  Test_counts,
  Test_empty_file,
  Test_untracked,
  Test_symlink,
  Test_same_second,
  Test_eol,
  Test_no_fetch_on_write,
  Test_highlights,
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

delete(TMP, 'rf')
writefile(empty(failed) ? [$'OK {len(TESTS)} tests'] : failed, OUT)
qall!
