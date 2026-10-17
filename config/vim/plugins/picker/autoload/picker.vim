vim9script

# The pickers: files, live grep, buffers, and LSP references and
# definitions.

import autoload './picker/ui.vim'
import autoload './picker/lsp.vim' as lsp_source

const RG_GLOBS = [
  '--glob', '!.git/*',
  '--glob', '!node_modules/*',
  '--glob', '!dist/*',
  '--glob', '!build/*',
]

def Notify(msg: string)
  echohl ErrorMsg
  echomsg $'picker: {msg}'
  echohl None
enddef

# Run `cmd` (no shell) and wait for its output lines; [] when it fails.
def Lines(cmd: list<string>): list<string>
  var state = {lines: [], code: -1, exited: false, closed: false}
  const job = job_start(cmd, {
    cwd: getcwd(),
    in_io: 'null',
    err_io: 'null',
    out_cb: (_, line) => {
      state.lines->add(line)
    },
    exit_cb: (_, code) => {
      state.code = code
      state.exited = true
    },
    close_cb: (_) => {
      state.closed = true
    },
  })
  if job_status(job) == 'fail'
    return []
  endif
  while !(state.exited && state.closed)
    sleep 5m
  endwhile
  return state.code == 0 ? state.lines : []
enddef

# ---------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------

export def FindFiles()
  if !executable('rg')
    Notify('rg is not installed')
    return
  endif
  const files = Lines(['rg', '--files', '--hidden', '--no-messages']
    + RG_GLOBS + ['--glob', '!.cache/*', '--glob', '!*.tmp', '--glob', '!*.log'])

  ui.Open({
    title: 'Find Files',
    initial_results: files,
    search: (query) => empty(query) ? files : matchfuzzy(files, query),
    format: (file) => file,
    preview: (file) => ({file: file}),
    select: (file) => {
      execute 'edit' fnameescape(file)
    },
  })
enddef

# ---------------------------------------------------------------------------
# Live grep
# ---------------------------------------------------------------------------

const MAX_RESULTS = 2000
const PUBLISH_INTERVAL_MS = 40

# Start rg for `query`; OnResults gets the results so far, at most every
# PUBLISH_INTERVAL_MS and once more at the end. Returns a function that
# stops the search.
def GrepAsync(query: string, OnResults: func(list<any>)): func()
  if empty(query)
    OnResults([])
    return () => {
    }
  endif

  var s = {active: true, finished: false, timer: -1, results: []}

  const Publish = () => {
    if s.active
      # A copy for the picker. Result dicts stay the same objects across
      # publications, so the preview can tell the selection hasn't changed.
      OnResults(copy(s.results))
    endif
  }

  const PublishLater = () => {
    if s.timer >= 0 || s.finished || !s.active
      return
    endif
    s.timer = timer_start(PUBLISH_INTERVAL_MS, (_) => {
      s.timer = -1
      # Cancellation or completion makes this queued update unnecessary.
      if s.active && !s.finished
        Publish()
      endif
    })
  }

  var job: job
  const Finish = () => {
    if !s.finished
      s.finished = true
      Publish()
    endif
  }

  # "--" ends option parsing, so a query beginning with "-" is not a flag.
  job = job_start(['rg', '--vimgrep', '--color=never', '--smart-case', '--hidden']
      + RG_GLOBS + ['--', query, '.'], {
    cwd: getcwd(),
    in_io: 'null',
    err_io: 'null',
    out_mode: 'nl',
    out_cb: (_, line) => {
      if !s.active || s.finished
        return
      endif
      const m = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\):\(.*\)$')
      if empty(m)
        return
      endif
      const file = m[1]->substitute('^\./', '', '')
      s.results->add({file: file, lnum: str2nr(m[2]), col: str2nr(m[3]), text: m[4]})
      if len(s.results) >= MAX_RESULTS
        # Stop the process rather than merely ignoring its output.
        job_stop(job)
        Finish()
        return
      endif
      PublishLater()
    },
    close_cb: (_) => {
      if s.active
        Finish()
      endif
    },
  })

  if job_status(job) == 'fail'
    s.active = false
    Notify('unable to start ripgrep; check that rg is installed')
    OnResults([])
    return () => {
    }
  endif

  # The picker calls this when the query changes or the picker closes.
  return () => {
    if !s.active
      return
    endif
    s.active = false
    if s.timer >= 0
      timer_stop(s.timer)
    endif
    if !s.finished
      s.finished = true
      job_stop(job)
    endif
  }
enddef

export def LiveGrep()
  if !executable('rg')
    Notify('rg is not installed')
    return
  endif
  ui.Open({
    title: 'Live Grep',
    search_async: GrepAsync,
    format: (r) => printf('%s:%d:%d: %s', r.file, r.lnum, r.col, r.text),
    preview: (r) => ({file: r.file, lnum: r.lnum, col: r.col}),
    select: OpenMatch,
  })
enddef

def OpenMatch(r: dict<any>)
  execute 'edit' fnameescape(r.file)
  cursor(min([r.lnum, line('$')]), max([r.col, 1]))
  normal! zz
enddef

# ---------------------------------------------------------------------------
# Buffers
# ---------------------------------------------------------------------------

export def FindBuffers()
  const buffers = getbufinfo({buflisted: 1})
    ->filter((_, b) => !empty(b.name))
    ->map((_, b) => ({bufnr: b.bufnr, path: b.name, display: fnamemodify(b.name, ':.')}))

  ui.Open({
    title: 'Find Buffers',
    initial_results: buffers,
    search: (query) => empty(query) ? buffers : matchfuzzy(buffers, query, {key: 'display'}),
    format: (b) => b.display,
    preview: (b) => ({file: b.path}),
    select: (b) => {
      if bufexists(b.bufnr)
        execute 'buffer' b.bufnr
      endif
    },
  })
enddef

# ---------------------------------------------------------------------------
# LSP
# ---------------------------------------------------------------------------

export def References()
  lsp_source.References()
enddef

export def Definitions()
  lsp_source.Definitions()
enddef
