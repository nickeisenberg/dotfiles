vim9script

# The repository a file belongs to, and the file's text at the base the
# buffer is compared against: the git index, or a revision such as HEAD.

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
  var chunks: list<string> = []
  var failed = false
  return job_start(['git', '--no-pager', 'show', Object(base, relpath)], {
    cwd: root,
    in_io: 'null',
    out_mode: 'raw',
    out_cb: (_, chunk) => {
      chunks->add(chunk)
    },
    err_cb: (_, _) => {
      failed = true
    },
    close_cb: (_) => {
      if failed
        Failed()
        return
      endif
      const text = join(chunks, '')
      const eol = text =~ '\n$'
      var lines = empty(text) ? [] : split(text, "\n", true)
      if eol
        remove(lines, -1)
      endif
      Done(lines, eol)
    },
  })
enddef

# Run git in `root` and wait for it, feeding `input` on stdin. For commands
# you run by hand (stage, blame), where waiting a moment is fine. Returns
# the output; v:shell_error is git's exit status.
export def Git(root: string, args: list<string>, input = ''): string
  const cmd = ['git', '-C', root, '--no-pager']->extend(args)->map((_, a) => shellescape(a))->join()
  return empty(input) ? system(cmd) : system(cmd, input)
enddef
