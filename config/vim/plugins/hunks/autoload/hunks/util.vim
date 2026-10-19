vim9script

# Small helpers shared by the other scripts.

# Every message to the user goes through here: highlighted, and kept in
# :messages.
export def Warn(msg: string)
  echohl WarningMsg
  echomsg $'hunks: {msg}'
  echohl None
enddef

# The options of the popups for a preview and a blame, at the cursor.
export const POPUP = {
  border: [],
  borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
  padding: [0, 1, 0, 1],
}

# A buffer's lines to diff against `base`: an empty buffer still has one
# empty line, which is no line at all when the base is empty too.
export def Lines(bufnr: number, base: list<string>): list<string>
  const lines = getbufline(bufnr, 1, '$')
  return lines == [''] && empty(base) ? [] : lines
enddef

# Start `cmd` in `cwd` (or Vim's directory when '') and call
# Done(exitval, stdout) once it has exited and its output is read; stderr
# is dropped. The exit and close callbacks come in either order, so this
# waits for both. Returns the job, so it can be stopped (Done then gets a
# nonzero exitval); a job that can't start calls Done(-1, '') right away.
export def Run(cmd: list<string>, cwd: string, Done: func(number, string)): job
  var chunks: list<string> = []
  var closed = false
  var exited = false
  var exitval = 0
  const Finish = () => {
    if closed && exited
      Done(exitval, join(chunks, ''))
    endif
  }
  var opts: dict<any> = {
    in_io: 'null',
    err_io: 'null',
    out_mode: 'raw',
    out_cb: (_, chunk) => {
      chunks->add(chunk)
    },
    close_cb: (_) => {
      closed = true
      Finish()
    },
    exit_cb: (_, status) => {
      exited = true
      exitval = status
      Finish()
    },
  }
  if !empty(cwd)
    opts.cwd = cwd
  endif
  const job = job_start(cmd, opts)
  if job_status(job) == 'fail'
    Done(-1, '')
  endif
  return job
enddef
