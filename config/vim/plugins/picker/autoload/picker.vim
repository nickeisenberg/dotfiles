vim9script

# The pickers: files, live grep, buffers, and LSP references and
# definitions.

import autoload './picker/ui.vim'
import autoload './picker/lsp.vim' as lsp_source
import autoload './picker/util.vim'

# Directories skipped at any depth ("**/"), not just at the top.
const RG_GLOBS = [
  '--glob', '!**/.git/**',
  '--glob', '!**/node_modules/**',
  '--glob', '!**/dist/**',
  '--glob', '!**/build/**',
]

const LINES_TIMEOUT_MS = 10000

def Noop()
enddef

# Run `cmd` (no shell) and wait for its output lines. The exit code is
# ignored: rg exits 2 when some directory is unreadable, even though it
# listed the rest. Gives up after LINES_TIMEOUT_MS; CTRL-C stops it too.
def Lines(cmd: list<string>): list<string>
  var state = {lines: [], closed: false}
  const job = job_start(cmd, {
    cwd: getcwd(),
    in_io: 'null',
    err_io: 'null',
    out_cb: (_, line) => {
      state.lines->add(line)
    },
    close_cb: (_) => {
      state.closed = true
    },
  })
  if job_status(job) == 'fail'
    return []
  endif
  const start = reltime()
  try
    while !state.closed
      if reltime(start)->reltimefloat() * 1000 > LINES_TIMEOUT_MS
        util.Notify($'{cmd[0]} took over {LINES_TIMEOUT_MS / 1000}s; the list is incomplete', true)
        break
      endif
      sleep 5m
    endwhile
  finally
    # After a timeout or CTRL-C.
    if job_status(job) == 'run'
      job_stop(job)
    endif
  endtry
  return state.lines
enddef

# ---------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------

export def FindFiles()
  if !executable('rg')
    util.Notify('rg is not installed', true)
    return
  endif
  const files = Lines(['rg', '--files', '--hidden', '--no-messages']
    + RG_GLOBS + ['--glob', '!**/.cache/**', '--glob', '!*.tmp', '--glob', '!*.log'])

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
# PUBLISH_INTERVAL_MS and once more at the end, with a message when the
# results were cut off or rg failed. Returns a function that stops the
# search.
def GrepAsync(query: string, OnResults: func(list<any>, string)): func()
  var s = {active: true, finished: false, timer: -1, results: [], errors: []}

  const Publish = () => {
    if !s.active
      return
    endif
    var message = ''
    if len(s.results) >= MAX_RESULTS
      message = $'[showing the first {MAX_RESULTS} matches]'
    elseif s.finished && empty(s.results) && !empty(s.errors)
      # Such as a regex parse error; its last line says what is wrong.
      message = $'[rg: {s.errors[-1]->substitute("^error: ", "", "")}]'
    endif
    # A copy for the picker. Result dicts stay the same objects across
    # publications, so the preview can tell the selection hasn't changed.
    OnResults(copy(s.results), message)
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
  # --no-messages hides unreadable-file noise; errors about the query
  # itself still come on stderr.
  job = job_start(['rg', '--vimgrep', '--color=never', '--smart-case', '--hidden', '--no-messages']
      + RG_GLOBS + ['--', query, '.'], {
    cwd: getcwd(),
    in_io: 'null',
    out_mode: 'nl',
    err_mode: 'nl',
    err_cb: (_, line) => {
      s.errors->add(line)
    },
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
    util.Notify('unable to start ripgrep; check that rg is installed', true)
    OnResults([], '')
    return Noop
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
    util.Notify('rg is not installed', true)
    return
  endif
  ui.Open({
    title: 'Live Grep',
    search_async: GrepAsync,
    format: (r) => util.LocationText(r.file, r.lnum, r.col, r.text),
    preview: (r) => ({file: r.file, lnum: r.lnum, col: r.col}),
    select: util.OpenLocation,
  })
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
    search: (query) => empty(query) ? buffers : util.FuzzyByKey(buffers, query, 'display'),
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
