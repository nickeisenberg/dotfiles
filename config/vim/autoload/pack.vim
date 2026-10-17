vim9script

# pack.vim: a small plugin manager.
#
#   pack#Begin()
#   Pack 'owner/repo'                     # GitHub shorthand, or a full git URL
#   Pack 'owner/repo', {branch: 'dev'}    # or {tag: 'v1.0'} or {commit: 'abc123'}
#   Pack 'owner/repo', {build: 'make'}    # shell command, ':VimCmd' or a Funcref
#   Pack 'owner/repo', {as: 'other-name'} # folder name to install under
#   Pack 'owner/repo', {enabled: false}   # keep it on disk but don't load it
#   Pack 'picker'                         # local: <vimdir>/plugins/picker
#   Pack '~/code/my-plugin'               # local: any path
#   pack#End()
#
# pack#End() clones missing plugins, then loads every enabled one: its
# directory goes on 'runtimepath' and its plugin/ files are sourced right
# away, so the lines after pack#End() can use the plugins' commands.
#
# Remote plugins are cloned into ~/.local/share/vim/pack/remote/opt
# ($XDG_DATA_HOME if set), or g:pack_dir when that is set first.
#
# Commands: :PackUpdate, :PackClean, :PackStatus, :PackBuild [name].

const vimdir = expand('<sfile>:p:h:h')
# Remote plugins are git clones; they live outside the config (which may
# itself be a git repository), like Neovim's stdpath('data').
const data_dir = $'{empty($XDG_DATA_HOME) ? $"{$HOME}/.local/share" : $XDG_DATA_HOME}/vim'
const remote_dir = get(g:, 'pack_dir', $'{data_dir}/pack/remote/opt')
const local_dir = $'{vimdir}/plugins'

const OPTIONS = ['as', 'branch', 'tag', 'commit', 'build', 'enabled']

# The plugins declared between Begin() and End(), in order.
var plugins: list<dict<any>> = []

# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------

def Info(msg: string)
  echomsg $'pack: {msg}'
enddef

def Error(msg: string)
  echohl ErrorMsg
  echomsg $'pack: {msg}'
  echohl None
enddef

# ---------------------------------------------------------------------------
# Running commands
# ---------------------------------------------------------------------------

# Git must never stop to ask for a password, passphrase or host key: the
# prompt would land on Vim's screen and the clone at startup would wait for
# it forever. Failing is better. A GIT_SSH_COMMAND of your own is kept.
def GitEnv(): dict<string>
  var env = {GIT_TERMINAL_PROMPT: '0'}
  if empty($GIT_SSH_COMMAND)
    env.GIT_SSH_COMMAND = 'ssh -o BatchMode=yes'
  endif
  return env
enddef

# Start `cmd` (a list, no shell) in `cwd`. Done(code, output) is called once
# the process has exited and all of its output has been read. Returns a dict
# whose `done` turns true at that point, for Wait().
def Spawn(cmd: list<string>, cwd: string, Done: func(number, list<string>)): dict<any>
  var state = {done: false, exited: false, closed: false, code: -1, output: []}

  const Finish = () => {
    if state.exited && state.closed && !state.done
      state.done = true
      Done(state.code, state.output)
    endif
  }

  const job = job_start(cmd, {
    cwd: cwd,
    in_io: 'null',
    env: GitEnv(),
    out_cb: (_, line) => {
      state.output->add(line)
    },
    err_cb: (_, line) => {
      state.output->add(line)
    },
    exit_cb: (_, code) => {
      state.code = code
      state.exited = true
      Finish()
    },
    close_cb: (_) => {
      state.closed = true
      Finish()
    },
  })

  if job_status(job) == 'fail'
    state.output = [$'failed to start: {cmd[0]}']
    state.code = -1
    state.exited = true
    state.closed = true
    Finish()
  endif
  return state
enddef

# (indexof() would do for these two, but Vim 9.0.0000 doesn't have it.)
def AllDone(states: list<dict<any>>): bool
  return empty(states->copy()->filter((_, s) => !s.done))
enddef

def IndexByName(name: string): number
  for i in range(len(plugins))
    if plugins[i].name == name
      return i
    endif
  endfor
  return -1
enddef

# Block until every state from Spawn() is done.
def Wait(states: list<dict<any>>)
  while !AllDone(states)
    sleep 10m
  endwhile
enddef

# Run git in `dir` and wait for it. Returns [exit code, output lines].
def Git(dir: string, args: list<string>): list<any>
  var result: list<any> = [-1, []]
  const state = Spawn(['git'] + args, dir, (code, output) => {
    result = [code, output]
  })
  Wait([state])
  return result
enddef

# ---------------------------------------------------------------------------
# Specs
# ---------------------------------------------------------------------------

export def Begin()
  plugins = []
  command! -nargs=+ -bar Pack Add(<args>)
enddef

def IsUrl(spec: string): bool
  return spec =~ '^\%(https\=\|ssh\|git\|file\)://' || spec =~ '^git@'
enddef

def IsLocal(spec: string): bool
  return !IsUrl(spec) && (spec !~ '/' || spec =~ '^[~./]')
enddef

def Add(spec: string, opts: dict<any> = {})
  for key in keys(opts)
    if index(OPTIONS, key) < 0
      Error($'{spec}: unknown option "{key}"')
      return
    endif
  endfor
  if len(['branch', 'tag', 'commit']->filter((_, k) => has_key(opts, k))) > 1
    Error($'{spec}: use only one of branch, tag and commit')
    return
  endif

  const is_local = IsLocal(spec)
  const trimmed = spec->substitute('/\+$', '', '')->substitute('\.git$', '', '')
  const name = opts->get('as', fnamemodify(trimmed, ':t'))

  var plugin: dict<any> = {
    name: name,
    local: is_local,
    branch: opts->get('branch', ''),
    tag: opts->get('tag', ''),
    commit: opts->get('commit', ''),
    build: opts->get('build', ''),
    enabled: !!opts->get('enabled', true),
  }

  if is_local
    plugin.dir = spec =~ '/' || spec =~ '^[~.]' ? fnamemodify(expand(trimmed), ':p')->substitute('/$', '', '') : $'{local_dir}/{spec}'
    plugin.url = ''
  else
    plugin.dir = $'{remote_dir}/{name}'
    plugin.url = IsUrl(spec) ? spec : $'https://github.com/{trimmed}.git'
  endif

  const existing = IndexByName(name)
  if existing >= 0
    Error($'"{name}" is declared twice; keeping the last one')
    plugins->remove(existing)
  endif
  plugins->add(plugin)
enddef

def Find(name: string): dict<any>
  const i = IndexByName(name)
  return i < 0 ? {} : plugins[i]
enddef

# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

def Load(plugin: dict<any>)
  const dir = plugin.dir
  var rtp = split(&runtimepath, ',')
  if index(rtp, dir) < 0
    # Right after the user's own directory, and its after/ directory right
    # before the user's after/, so the user's files always win.
    rtp->insert(dir, index(rtp, vimdir) + 1)
    if isdirectory($'{dir}/after')
      const user_after = index(rtp, $'{vimdir}/after')
      rtp->insert($'{dir}/after', user_after < 0 ? len(rtp) : user_after)
    endif
    &runtimepath = join(rtp->mapnew((_, p) => escape(p, ',')), ',')
  endif

  for file in glob($'{dir}/plugin/**/*.vim', true, true)
    execute 'source' fnameescape(file)
  endfor

  if exists('g:did_load_filetypes')
    for file in glob($'{dir}/ftdetect/*.vim', true, true)
      augroup filetypedetect
        execute 'source' fnameescape(file)
      augroup END
    endfor
  endif
enddef

export def End()
  if !isdirectory(remote_dir)
    mkdir(remote_dir, 'p')
  endif

  const missing = plugins->copy()->filter((_, p) => !p.local && p.enabled && !isdirectory(p.dir))
  const installed = Install(missing)

  for plugin in plugins
    if !plugin.enabled
      continue
    endif
    if !isdirectory(plugin.dir)
      if plugin.local
        Error($'{plugin.name}: {plugin.dir} does not exist')
      endif
      continue
    endif
    Load(plugin)
  endfor

  for plugin in installed
    Build(plugin)
  endfor
enddef

# ---------------------------------------------------------------------------
# Installing
# ---------------------------------------------------------------------------

def Helptags(plugin: dict<any>)
  if isdirectory($'{plugin.dir}/doc')
    silent! execute 'helptags' fnameescape($'{plugin.dir}/doc')
  endif
enddef

# Clone `missing` in parallel and wait. Returns the plugins that installed.
def Install(missing: list<dict<any>>): list<dict<any>>
  if empty(missing)
    return []
  endif

  Info($'installing {missing->mapnew((_, p) => p.name)->join(", ")}')
  redraw

  var states: list<dict<any>> = []
  var installed: list<dict<any>> = []
  for plugin in missing
    var cmd = ['git', 'clone', '--quiet', '--filter=blob:none', '--recurse-submodules']
    const ref = !empty(plugin.branch) ? plugin.branch : plugin.tag
    if !empty(ref)
      cmd += ['--branch', ref]
    endif
    cmd += [plugin.url, plugin.dir]

    const p = plugin
    states->add(Spawn(cmd, vimdir, (code, output) => {
      if code != 0
        Error($'{p.name}: clone failed: {output->join(" ")}')
        delete(p.dir, 'rf')
      else
        installed->add(p)
      endif
    }))
  endfor
  Wait(states)

  for plugin in installed->copy()
    if !empty(plugin.commit)
      const [code, output] = Git(plugin.dir, ['checkout', '--quiet', plugin.commit])
      if code != 0
        Error($'{plugin.name}: checkout {plugin.commit} failed: {output->join(" ")}')
      endif
    endif
    Helptags(plugin)
    Info($'installed {plugin.name}')
  endfor
  return installed
enddef

# ---------------------------------------------------------------------------
# Building
# ---------------------------------------------------------------------------

# Run a plugin's build: a shell command (async, in the plugin's directory),
# a ':' Vim command, or a Funcref called with the plugin's info.
def Build(plugin: dict<any>)
  const B = plugin.build
  if type(B) == v:t_string && empty(B)
    return
  endif

  const info = {name: plugin.name, dir: plugin.dir, url: plugin.url, local: plugin.local}

  if type(B) == v:t_func
    try
      call(B, [info])
      Info($'built {plugin.name}')
    catch
      Error($'{plugin.name}: build failed: {v:exception}')
    endtry
  elseif B[0] == ':'
    try
      execute B[1 :]
      Info($'built {plugin.name}')
    catch
      Error($'{plugin.name}: build failed: {v:exception}')
    endtry
  else
    Info($'building {plugin.name}: {B}')
    # 'shell' can carry arguments ("/bin/bash --login").
    Spawn(split(&shell) + [&shellcmdflag, B], plugin.dir, (code, output) => {
      if code == 0
        Info($'built {plugin.name}')
      else
        Error($'{plugin.name}: build exited with {code}: {output[-5 :]->join(" | ")}')
      endif
    })
  endif
enddef

def CmdBuild(name: string)
  if !empty(name)
    const plugin = Find(name)
    if empty(plugin)
      Error($'no plugin named "{name}"')
      return
    endif
    Build(plugin)
    return
  endif
  for plugin in plugins
    if plugin.enabled && isdirectory(plugin.dir)
      Build(plugin)
    endif
  endfor
enddef

# ---------------------------------------------------------------------------
# A scratch buffer for reports
# ---------------------------------------------------------------------------

def Report(name: string, lines: list<string>)
  const bufname = $'pack://{name}'
  const win = bufwinid(bufname)
  if win > 0
    win_gotoid(win)
  else
    silent execute 'botright new' fnameescape(bufname)
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap
    setlocal nonumber norelativenumber nocursorline nocursorcolumn colorcolumn=
    nnoremap <buffer> <nowait> q <Cmd>close<CR>
  endif
  setlocal modifiable
  silent :%delete _
  setline(1, lines)
  setlocal nomodifiable
  execute 'resize' min([len(lines) + 1, &lines / 2])
  syntax match PackName /^\S\+\ze:/
  syntax match PackHash /^  \zs\x\{7,}\>/
  syntax match PackError /\<\%(failed\|error\|not found\)\>.*/
  highlight default link PackName Title
  highlight default link PackHash Identifier
  highlight default link PackError ErrorMsg
  redraw
enddef

def ReportAppend(name: string, lines: list<string>)
  const buf = bufnr($'pack://{name}')
  if buf < 0
    return
  endif
  setbufvar(buf, '&modifiable', true)
  appendbufline(buf, '$', lines)
  setbufvar(buf, '&modifiable', false)
  redraw
enddef

# ---------------------------------------------------------------------------
# :PackUpdate
# ---------------------------------------------------------------------------

def Rev(dir: string, ref: string): string
  const [code, output] = Git(dir, ['rev-parse', '--verify', '--quiet', $'{ref}^{{commit}}'])
  return code == 0 && !empty(output) ? output[0] : ''
enddef

# The branch a branch-tracking plugin should be on: its `branch`, else the
# remote's default branch.
def WantedBranch(plugin: dict<any>): string
  if !empty(plugin.branch)
    return plugin.branch
  endif
  const [code, output] = Git(plugin.dir, ['rev-parse', '--abbrev-ref', 'origin/HEAD'])
  return code == 0 && !empty(output) ? output[0]->substitute('^origin/', '', '') : ''
enddef

# What `plugin` should move to after a fetch: {target, branch} or {error}.
def Target(plugin: dict<any>): dict<string>
  if !empty(plugin.commit)
    return {target: plugin.commit, branch: ''}
  endif
  if !empty(plugin.tag)
    return {target: $'refs/tags/{plugin.tag}', branch: ''}
  endif
  const branch = WantedBranch(plugin)
  if empty(branch)
    return {error: 'cannot tell the default branch (set one with branch:)'}
  endif
  return {target: $'origin/{branch}', branch: branch}
enddef

def CmdUpdate()
  const targets = plugins->copy()->filter((_, p) => !p.local && p.enabled)
  const missing = targets->copy()->filter((_, p) => !isdirectory(p.dir))
  for plugin in Install(missing)
    Load(plugin)
    Build(plugin)
  endfor

  const present = targets->copy()->filter((_, p) => isdirectory(p.dir))
  if empty(present)
    Info('no remote plugins')
    return
  endif

  Report('update', [$'Fetching {len(present)} plugins...'])

  var states: list<dict<any>> = []
  var fetched: dict<list<any>> = {}
  for plugin in present
    const p = plugin
    states->add(Spawn(['git', 'fetch', '--quiet', '--tags', '--force', 'origin'], p.dir, (code, output) => {
      fetched[p.name] = [code, output]
      ReportAppend('update', [$'  fetched {p.name}' .. (code == 0 ? '' : ' (failed)')])
    }))
  endfor

  # Wait without blocking: check back until every fetch is done.
  timer_start(50, (timer) => {
    if !AllDone(states)
      return
    endif
    timer_stop(timer)
    ReviewUpdates(present, fetched)
  }, {repeat: -1})
enddef

def ReviewUpdates(present: list<dict<any>>, fetched: dict<list<any>>)
  var lines: list<string> = []
  var pending: list<dict<any>> = []

  for plugin in present
    const [code, output] = fetched[plugin.name]
    if code != 0
      lines->add($'{plugin.name}: fetch failed: {output->join(" ")}')
      continue
    endif

    const want = Target(plugin)
    if has_key(want, 'error')
      lines->add($'{plugin.name}: error: {want.error}')
      continue
    endif

    const head = Rev(plugin.dir, 'HEAD')
    const target = Rev(plugin.dir, want.target)
    if empty(target)
      lines->add($'{plugin.name}: error: {want.target} not found')
      continue
    endif

    if head == target
      lines->add($'{plugin.name}: up to date')
      continue
    endif

    const [_, log] = Git(plugin.dir, ['log', '--oneline', '--no-decorate', $'HEAD..{target}'])
    if empty(log)
      lines->add($'{plugin.name}: move to {target[: 6]} ({want.target})')
    else
      lines->add($'{plugin.name}: {len(log)} new commit{len(log) == 1 ? "" : "s"}')
      lines += log->mapnew((_, l) => $'  {l}')
    endif
    pending->add({plugin: plugin, target: target, branch: want.branch})
  endfor

  Report('update', lines)
  if empty(pending)
    Info('everything is up to date')
    return
  endif

  const n = len(pending)
  if confirm($'Apply {n} update{n == 1 ? "" : "s"}?', "&Yes\n&No", 2) != 1
    ReportAppend('update', ['', 'Not applied.'])
    return
  endif

  var results: list<string> = ['']
  for item in pending
    const plugin = item.plugin
    var code: number
    var output: list<string>
    if empty(item.branch)
      [code, output] = Git(plugin.dir, ['checkout', '--quiet', item.target])
    else
      const [_, current] = Git(plugin.dir, ['symbolic-ref', '--quiet', '--short', 'HEAD'])
      if !empty(current) && current[0] == item.branch
        [code, output] = Git(plugin.dir, ['merge', '--ff-only', '--quiet', item.target])
      else
        [code, output] = Git(plugin.dir, ['checkout', '--quiet', '-B', item.branch, $'origin/{item.branch}'])
      endif
    endif

    if code != 0
      results->add($'{plugin.name}: update failed: {output->join(" ")}')
      continue
    endif
    Git(plugin.dir, ['submodule', 'update', '--init', '--recursive', '--quiet'])
    Helptags(plugin)
    results->add($'{plugin.name}: updated')
    Build(plugin)
  endfor
  results->add('Restart Vim to load the new versions.')
  ReportAppend('update', results)
enddef

# ---------------------------------------------------------------------------
# :PackClean
# ---------------------------------------------------------------------------

def CmdClean()
  const known = plugins->copy()->filter((_, p) => !p.local)->map((_, p) => p.dir)
  const stray = glob($'{remote_dir}/*', true, true)
    ->filter((_, d) => isdirectory(d) && index(known, d) < 0)

  if empty(stray)
    Info('nothing to clean')
    return
  endif

  Report('clean', ['Not in the plugin list:'] + stray->mapnew((_, d) => $'  {fnamemodify(d, ":t")}'))
  const n = len(stray)
  if confirm($'Delete {n} folder{n == 1 ? "" : "s"}?', "&Yes\n&No", 2) != 1
    ReportAppend('clean', ['', 'Nothing deleted.'])
    return
  endif
  for dir in stray
    delete(dir, 'rf')
  endfor
  ReportAppend('clean', ['', $'Deleted {n}.'])
enddef

# ---------------------------------------------------------------------------
# :PackStatus
# ---------------------------------------------------------------------------

def CmdStatus()
  var rows: list<list<string>> = []
  for plugin in plugins
    var where = plugin.local ? 'local' : 'remote'
    var ref = ''
    var hash = ''
    var flags: list<string> = []

    if !plugin.enabled
      flags->add('disabled')
    endif

    if !isdirectory(plugin.dir)
      flags->add('missing')
    elseif !plugin.local
      const [_, head] = Git(plugin.dir, ['rev-parse', '--short', 'HEAD'])
      hash = get(head, 0, '')
      if !empty(plugin.commit)
        ref = $'commit {plugin.commit[: 6]}'
      elseif !empty(plugin.tag)
        ref = $'tag {plugin.tag}'
      else
        const [_, br] = Git(plugin.dir, ['symbolic-ref', '--quiet', '--short', 'HEAD'])
        ref = get(br, 0, '(detached)')
        const [c, behind] = Git(plugin.dir, ['rev-list', '--count', 'HEAD..@{upstream}'])
        if c == 0 && get(behind, 0, '0') != '0'
          flags->add($'{behind[0]} behind')
        endif
      endif
      const [_, dirty] = Git(plugin.dir, ['status', '--porcelain', '--untracked-files=no'])
      if !empty(dirty)
        flags->add('local changes')
      endif
    endif

    var last = empty(flags) ? '' : $'[{flags->join(", ")}]'
    if plugin.local
      last = $'{fnamemodify(plugin.dir, ":~")} {last}'
    endif
    rows->add([$'{plugin.name}:', where, ref, hash, last])
  endfor

  # Line the columns up.
  var widths = [0, 0, 0, 0]
  for row in rows
    for i in range(4)
      widths[i] = max([widths[i], strdisplaywidth(row[i])])
    endfor
  endfor
  const lines = rows->mapnew((_, row) =>
    range(4)->mapnew((_, i) => row[i] .. repeat(' ', widths[i] - strdisplaywidth(row[i])))
      ->join('  ') .. '  ' .. row[4])
    ->map((_, l) => substitute(l, '\s\+$', '', ''))

  Report('status', lines)
enddef

def NameComplete(arglead: string, _cmdline: string, _pos: number): list<string>
  return plugins->mapnew((_, p) => p.name)->filter((_, n) => n->stridx(arglead) == 0)
enddef

command! -bar PackUpdate CmdUpdate()
command! -bar PackClean CmdClean()
command! -bar PackStatus CmdStatus()
command! -bar -nargs=? -complete=customlist,NameComplete PackBuild CmdBuild(<q-args>)
