vim9script

# Format a buffer with its filetype's pipeline, or the attached LSP.

# Commands already reported missing, so a missing tool warns once per
# session instead of on every save.
var warned: dict<bool> = {}

def Notify(msg: string, warn = false)
  if warn
    echohl WarningMsg
  endif
  echomsg $'format: {msg}'
  if warn
    echohl None
  endif
enddef

def Timeout(): number
  return get(g:, 'format_timeout_ms', 5000)
enddef

# ---------------------------------------------------------------------------
# Running the pipeline
# ---------------------------------------------------------------------------

def Command(step: any, bufname: string): list<string>
  if type(step) == v:t_func
    return call(step, [bufname])
  endif
  return step->mapnew((_, arg) => arg == '%' ? bufname : arg)
enddef

# Run `cmd` with `input` on stdin. Returns {code, out, err}, or {} after
# killing it when it takes longer than the timeout.
def Run(cmd: list<string>, input: string): dict<any>
  var result = {code: -1, out: '', err: '', exited: false, closed: false}
  const job = job_start(cmd, {
    in_io: 'pipe',
    out_mode: 'raw',
    err_mode: 'raw',
    out_cb: (_, data) => {
      result.out ..= data
    },
    err_cb: (_, data) => {
      result.err ..= data
    },
    exit_cb: (_, code) => {
      result.code = code
      result.exited = true
    },
    close_cb: (_) => {
      result.closed = true
    },
  })
  if job_status(job) == 'fail'
    return {code: -1, out: '', err: 'failed to start'}
  endif

  const channel = job_getchannel(job)
  ch_sendraw(channel, input)
  ch_close_in(channel)

  const start = reltime()
  while !(result.exited && result.closed)
    if reltimefloat(reltime(start)) * 1000 > Timeout()
      job_stop(job, 'kill')
      return {}
    endif
    sleep 2m
  endwhile
  return result
enddef

# Every command must exist before any of them runs; a pipeline that stops
# halfway would leave the text partly formatted.
def CheckCommands(cmds: list<list<string>>): bool
  for cmd in cmds
    if !executable(cmd[0])
      if !warned->get(cmd[0], false)
        warned[cmd[0]] = true
        Notify($'formatter not found: {cmd[0]}', true)
      endif
      return false
    endif
  endfor
  return true
enddef

# Run the pipeline over `text`. Returns the formatted text, or null when a
# step is missing, fails or times out (the failure is reported).
def Pipeline(cmds: list<list<string>>, input: string): string
  if !CheckCommands(cmds)
    return null_string
  endif

  var text = input
  for cmd in cmds
    const result = Run(cmd, text)
    if empty(result)
      Notify($'{cmd[0]} timed out after {Timeout()} ms', true)
      return null_string
    endif
    if result.code != 0
      var err = trim(result.err)
      if empty(err)
        err = $'exited with code {result.code}'
      endif
      Notify($'{cmd[0]}: {err}', true)
      return null_string
    endif
    # Some tools print nothing when there is nothing to change; keep the
    # current text rather than emptying the buffer.
    if !empty(result.out)
      text = result.out
    endif
  endfor
  return text
enddef

# ---------------------------------------------------------------------------
# Writing the result back
# ---------------------------------------------------------------------------

# Replace the buffer's lines with `new` by applying a line diff, so marks,
# folds, signs and the cursor on untouched lines stay put. A Vim without
# diff() (before 9.1.0071) replaces every line instead.
def Apply(bufnr: number, new: list<string>)
  const old = getbufline(bufnr, 1, '$')
  if old == new
    return
  endif
  if !exists('*diff')
    setbufline(bufnr, 1, new)
    if len(old) > len(new)
      deletebufline(bufnr, len(new) + 1, len(old))
    endif
    return
  endif

  # Through call(), so a Vim without diff() can still compile this.
  var hunks = call('diff', [old, new, {output: 'indices'}])
  # Bottom up, so earlier hunks' line numbers stay valid.
  for hunk in reverse(hunks)
    const first = hunk.from_idx
    const n = min([hunk.from_count, hunk.to_count])
    const replacement = new[hunk.to_idx : hunk.to_idx + hunk.to_count - 1]
    if n > 0
      setbufline(bufnr, first + 1, replacement[: n - 1])
    endif
    if hunk.from_count > n
      deletebufline(bufnr, first + n + 1, first + hunk.from_count)
    elseif hunk.to_count > n
      appendbufline(bufnr, first + n, replacement[n :])
    endif
  endfor
enddef

# ---------------------------------------------------------------------------
# LSP fallback
# ---------------------------------------------------------------------------

def FormatWithLsp(bufnr: number)
  if !exists('g:loaded_lsp') || bufnr != bufnr()
    return
  endif
  var server: dict<any>
  try
    server = lsp#buffer#BufLspServerGet(bufnr, 'documentFormatting')
  catch
    return
  endtry
  if !empty(server) && server->get('running', false) && server->get('ready', false)
    LspFormat
  endif
enddef

# ---------------------------------------------------------------------------

# Special or read-only buffers are never formatted.
def Formattable(bufnr: number): bool
  return bufexists(bufnr) && bufloaded(bufnr)
    && empty(getbufvar(bufnr, '&buftype'))
    && getbufvar(bufnr, '&modifiable')
enddef

export def Format(bufnr: number)
  if !Formattable(bufnr)
    return
  endif

  const filetype = getbufvar(bufnr, '&filetype')
  const steps = get(g:, 'format_formatters', {})->get(filetype, [])
  if empty(steps)
    FormatWithLsp(bufnr)
    return
  endif

  # Give tools a plausible file name for unnamed buffers; ruff and others
  # use it to choose settings.
  var bufname = bufname(bufnr)
  bufname = empty(bufname) ? $'stdin.{filetype}' : fnamemodify(bufname, ':p')

  const cmds = steps->mapnew((_, step) => Command(step, bufname))
  const input = getbufline(bufnr, 1, '$')->join("\n") .. "\n"
  const output = Pipeline(cmds, input)
  if output == null_string
    return
  endif

  # Buffers hold lines without the final newline.
  var lines = split(output, "\n", true)
  if !empty(lines) && lines[-1] == ''
    remove(lines, -1)
  endif
  Apply(bufnr, lines->map((_, l) => substitute(l, '\r$', '', '')))
enddef
