vim9script

# The repository a file belongs to, and the file's text at the base the
# buffer is compared against: the git index, or a revision such as HEAD.

import autoload './util.vim'

# file path -> repository root, or '' outside a repository.
var roots: dict<string> = {}

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

# Forget the roots found so far: a `git init` can put a path in a repository.
export def ForgetRoots()
  roots = {}
enddef

# The git directory for a root: .git itself, or where a .git file
# ("gitdir: <path>") points.
export def GitDir(root: string): string
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

# Changes when the base may have changed: the index is rewritten by add,
# commit, checkout and reset, and logs/HEAD by anything that moves HEAD.
export def Stamp(root: string): list<number>
  const dir = GitDir(root)
  return [getftime($'{dir}/index'), getfsize($'{dir}/index'), getftime($'{dir}/logs/HEAD')]
enddef

# The object name of a file at `base`: ':./path' for the index, else
# 'REV:./path'. The ./ makes the path relative to the root, the job's cwd.
def Object(base: string, relpath: string): string
  return base == 'index' ? $':./{relpath}' : $'{base}:./{relpath}'
enddef

# Fetch the text of `relpath` at `base` in the background, then call
# Done(lines, eol), where eol tells whether the text ends with a newline,
# or Failed() when git fails, e.g. for a file that isn't tracked. Returns
# the job, so a newer fetch can stop it.
export def FetchBase(root: string, relpath: string, base: string,
    Done: func(list<string>, bool), Failed: func()): job
  # Failure is told by the exit status: git can warn on stderr and still
  # succeed (e.g. "refname 'main' is ambiguous").
  return util.Run(['git', '--no-pager', 'show', Object(base, relpath)], root,
    (status, text) => {
      if status != 0
        Failed()
        return
      endif
      const eol = text =~ '\n$'
      var lines = empty(text) ? [] : split(text, "\n", true)
      if eol
        remove(lines, -1)
      endif
      Done(lines, eol)
    })
enddef

# Run git in `root` and wait for it, feeding `input` on stdin. For commands
# you run by hand (stage, blame), where waiting a moment is fine. Git runs
# as a job rather than with system(), which would start 'shell' each time
# (a login shell in this config takes ~0.3s). Returns {output, error, ok}:
# stdout, stderr, and whether git exited with 0 within 10 seconds.
export def Git(root: string, args: list<string>, input = ''): dict<any>
  var out: list<string> = []
  var err: list<string> = []
  var closed = false
  const job = job_start(['git', '-C', root, '--no-pager'] + args, {
    in_io: 'pipe',
    mode: 'raw',
    out_cb: (_, chunk) => {
      out->add(chunk)
    },
    err_cb: (_, chunk) => {
      err->add(chunk)
    },
    close_cb: (_) => {
      closed = true
    },
  })
  if job_status(job) == 'fail'
    return {output: '', error: 'git could not be started', ok: false}
  endif
  const channel = job_getchannel(job)
  if !empty(input)
    ch_sendraw(channel, input)
  endif
  ch_close_in(channel)
  # Callbacks run while sleeping.
  for _ in range(10000)
    if closed && job_status(job) != 'run'
      return {output: join(out, ''), error: join(err, ''),
              ok: job_info(job).exitval == 0}
    endif
    sleep 1m
  endfor
  job_stop(job, 'kill')
  return {output: join(out, ''), error: $'git {args[0]} timed out', ok: false}
enddef
