vim9script

# Format a buffer with its filetype's pipeline, or the attached LSP.

# Commands already reported missing, so a missing tool warns once per
# session instead of on every save.
var warned: dict<bool> = {}

# File extensions for filetypes whose name is not their extension, used to
# name unnamed buffers.
const extensions = {
  python: 'py', javascript: 'js', typescript: 'ts', markdown: 'md',
  rust: 'rs', ruby: 'rb', haskell: 'hs',
}

# A multi-line message (a tool's stderr) is shown one line per message.
def Notify(msg: string, warn = false)
  if warn
    echohl WarningMsg
  endif
  for line in split(msg, '\r\=\n')
    echomsg $'format: {line}'
  endfor
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

# Run `cmd` with `input` on stdin. Always returns {code, out, err,
# timedout}: code is -1 when the job could not start (err says so) or was
# killed after the timeout (timedout is true).
#
# stdin comes from a temp file rather than a pipe: writing a large buffer
# into a pipe while the tool's stdout is not yet being read deadlocks with
# tools that write as they read (sed, tr, cat), and fails with E631 when a
# tool exits without reading.
def Run(cmd: list<string>, input: string): dict<any>
  var result = {code: -1, out: '', err: '', timedout: false}
  var done = {exited: false, closed: false}
  const infile = tempname()
  # 'b': `input` already ends in a newline, so add none after the last line.
  writefile(split(input, "\n", true), infile, 'b')
  try
    const job = job_start(cmd, {
      in_io: 'file',
      in_name: infile,
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
        done.exited = true
      },
      close_cb: (_) => {
        done.closed = true
      },
    })
    if job_status(job) == 'fail'
      result.err = 'failed to start'
      return result
    endif

    const start = reltime()
    while !(done.exited && done.closed)
      if reltimefloat(reltime(start)) * 1000 > Timeout()
        job_stop(job, 'kill')
        result.code = -1
        result.timedout = true
        return result
      endif
      sleep 2m
    endwhile
  finally
    delete(infile)
  endtry
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

# Run the pipeline over `input`. Returns the formatted text, or null when a
# step is missing, fails or times out (the failure is reported).
def Pipeline(cmds: list<list<string>>, input: string): string
  if !CheckCommands(cmds)
    return null_string
  endif

  var text = input
  for cmd in cmds
    const result = Run(cmd, text)
    if result.timedout
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

# exists('*diff') isn't enough: a Vim built without the internal diff
# (Apple's /usr/bin/vim, no "internal" in 'diffopt') has diff() but it
# returns 0, so call it once and check for a list.
def DiffWorks(): bool
  try
    return exists('*diff')
      && type(call('diff', [['a'], ['b'], {output: 'indices'}])) == v:t_list
  catch
    return false
  endtry
enddef

const HAS_DIFF = DiffWorks()

# Replace the buffer's lines with `new` by applying a line diff, so marks,
# folds, signs and the cursor on untouched lines stay put. A Vim without
# diff() (before 9.1.0071) replaces every line instead.
def Apply(bufnr: number, new: list<string>)
  const old = getbufline(bufnr, 1, '$')
  if old == new
    return
  endif
  if !HAS_DIFF
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
    const replacement = hunk.to_count > 0
      ? new[hunk.to_idx : hunk.to_idx + hunk.to_count - 1]
      : []
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

# :LspFormat only formats the current buffer, so other buffers (as in
# :wall) are left alone. It goes through :execute because this function
# is compiled with Format() and the command may not exist (no yegappan/lsp).
# BufLspServerGet() only returns a ready server that can format.
def FormatWithLsp(bufnr: number)
  if exists(':LspFormat') != 2 || bufnr != bufnr()
    return
  endif
  if !empty(lsp#buffer#BufLspServerGet(bufnr, 'documentFormatting'))
    execute 'LspFormat'
  endif
enddef

# ---------------------------------------------------------------------------

# Special or unmodifiable buffers are never formatted. 'readonly' alone
# does not stop it, so :w! on a read-only file still formats.
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
  # use it to choose settings. Most filetypes are also their extension.
  var bufname = bufname(bufnr)
  if empty(bufname)
    const ext = get(extensions, filetype, filetype)
    bufname = $'stdin.{ext}'
  else
    bufname = fnamemodify(bufname, ':p')
  endif

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
  # Drop CRs the tool added as line endings, but keep real ones that were
  # already in the text.
  if getbufvar(bufnr, '&fileformat') == 'dos' || stridx(input, "\r") < 0
    lines->map((_, l) => substitute(l, '\r$', '', ''))
  endif
  Apply(bufnr, lines)
enddef
