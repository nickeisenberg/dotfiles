vim9script

# Hunks between the base and the buffer, and the backends that compute
# them.
#
# A hunk is {old_start, old_count, new_start, new_count}: base lines
# [old_start, old_start + old_count) became buffer lines
# [new_start, new_start + new_count), both 0-based. When a count is 0, its
# start is where the lines were inserted or removed: old_count 0 means lines
# were added before base line old_start.
#
# Every backend has the same signature, the Differ interface:
#
#   func(bufnr, base: list<string>, lines: list<string>, Done)
#
# and calls Done(hunks), right away or later. `Differ` below is declared
# with that type, so a backend with another signature fails when this
# script loads. Which one runs is picked once,
# from g:hunks_diff:
#
#   builtin  Vim's diff() (9.1.0071 and later), in memory
#   job      the base and the buffer written to temp files, and
#            `git diff --no-index` run on them in the background
#   auto     builtin where diff() exists, else job (the default)

const HAS_DIFF = exists('*diff')

# ---------------------------------------------------------------------------
# builtin: diff()
# ---------------------------------------------------------------------------

export def BuiltinDiffer(bufnr: number, base: list<string>, lines: list<string>,
    Done: func(list<dict<number>>))
  # Through call(), so a Vim without diff() can still compile this.
  const found = call('diff', [base, lines, {output: 'indices'}])
  Done(found->mapnew((_, h) => ({
    old_start: h.from_idx, old_count: h.from_count,
    new_start: h.to_idx, new_count: h.to_count,
  })))
enddef

# ---------------------------------------------------------------------------
# job: git diff --no-index on temp files
# ---------------------------------------------------------------------------

# bufnr -> {base: the list last written, base_file, buf_file, job, seq},
# where seq counts the jobs started, so a stopped one's output is ignored.
var files: dict<dict<any>> = {}

# The hunks of `git diff -U0` output: "@@ -a,b +c,d @@", a count defaults
# to 1. A start is 1-based, except that with a count of 0 it is the line
# the change comes after, which is the 0-based position we want.
export def ParseHunks(output: list<string>): list<dict<number>>
  var hunks: list<dict<number>> = []
  for line in output
    const m = matchlist(line, '^@@ -\(\d\+\)\%(,\(\d\+\)\)\= +\(\d\+\)\%(,\(\d\+\)\)\= @@')
    if empty(m)
      continue
    endif
    const old_count = empty(m[2]) ? 1 : str2nr(m[2])
    const new_count = empty(m[4]) ? 1 : str2nr(m[4])
    hunks->add({
      old_start: old_count == 0 ? str2nr(m[1]) : str2nr(m[1]) - 1,
      old_count: old_count,
      new_start: new_count == 0 ? str2nr(m[3]) : str2nr(m[3]) - 1,
      new_count: new_count,
    })
  endfor
  return hunks
enddef

export def JobDiffer(bufnr: number, base: list<string>, lines: list<string>,
    Done: func(list<dict<number>>))
  if !has_key(files, bufnr)
    files[bufnr] = {base: [], base_file: tempname(), buf_file: tempname(), seq: 0}
  endif
  var f = files[bufnr]
  if has_key(f, 'job') && job_status(f.job) == 'run'
    job_stop(f.job)
  endif
  # The base only changes when it is fetched again, as a new list.
  if f.base isnot base
    writefile(base, f.base_file)
    f.base = base
  endif
  writefile(lines, f.buf_file)

  f.seq += 1
  const seq = f.seq
  var output: list<string> = []
  var failed = false
  f.job = job_start(['git', '--no-pager', 'diff', '--no-index', '--no-color',
      '--no-ext-diff', '-U0', '--', f.base_file, f.buf_file], {
    in_io: 'null',
    out_cb: (_, line) => {
      output->add(line)
    },
    err_cb: (_, _) => {
      failed = true
    },
    close_cb: (_) => {
      # Skip a job that was stopped for a newer one, and errors. Exit
      # status 1 just means the files differ, so the status isn't used.
      if !failed && files->get(bufnr, {})->get('seq', -1) == seq
        Done(ParseHunks(output))
      endif
    },
  })
enddef

# Drop a buffer's temp files.
export def Forget(bufnr: number)
  if has_key(files, bufnr)
    delete(files[bufnr].base_file)
    delete(files[bufnr].buf_file)
    remove(files, bufnr)
  endif
enddef

# ---------------------------------------------------------------------------
# The interface
# ---------------------------------------------------------------------------

def Pick(): func(number, list<string>, list<string>, func(list<dict<number>>))
  var name = get(g:, 'hunks_diff', 'auto')
  if name == 'builtin' && !HAS_DIFF
    echohl WarningMsg
    echomsg "hunks: this Vim has no diff(), using g:hunks_diff = 'job'"
    echohl None
    name = 'job'
  elseif name != 'builtin' && name != 'job'
    name = HAS_DIFF ? 'builtin' : 'job'
  endif
  return name == 'builtin' ? BuiltinDiffer : JobDiffer
enddef

const Differ: func(number, list<string>, list<string>, func(list<dict<number>>)) = Pick()

export def Hunks(bufnr: number, base: list<string>, lines: list<string>,
    Done: func(list<dict<number>>))
  Differ(bufnr, base, lines, Done)
enddef

# The buffer lines a hunk is shown on, 1-based [first, last]. Removed lines
# show on the line above them, or on line 1 when nothing is above.
export def Span(h: dict<number>): list<number>
  if h.new_count == 0
    const lnum = max([h.new_start, 1])
    return [lnum, lnum]
  endif
  return [h.new_start + 1, h.new_start + h.new_count]
enddef
