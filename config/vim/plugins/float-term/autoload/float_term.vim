vim9script

var winid = 0
var current = 0          # index into `buffers`, valid when it isn't empty
var buffers: list<number> = []

const BORDER = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

def IsOpen(): bool
  return winid > 0 && !empty(popup_getpos(winid))
enddef

# Forget terminals whose shell has exited (their buffers are wiped).
def Prune()
  const was = empty(buffers) ? -1 : buffers[current]
  buffers->filter((_, b) => bufexists(b))
  if empty(buffers)
    current = 0
    return
  endif
  const at = index(buffers, was)
  current = at >= 0 ? at : min([current, len(buffers) - 1])
enddef

# A title in the middle of the top border.
def Title(text: string, width: number): string
  const left = max([(width - strchars(text)) / 2, 0])
  return repeat(BORDER[0], left) .. text
enddef

def Open()
  Prune()
  if empty(buffers)
    return
  endif
  const width = &columns * 3 / 4
  const height = &lines * 3 / 4
  const bufnr = buffers[current]

  winid = popup_create(bufnr, {
    pos: 'center',
    minwidth: width,
    maxwidth: width,
    minheight: height,
    maxheight: height,
    border: [],
    borderchars: BORDER,
    title: Title($' {current + 1}/{len(buffers)} ', width),
    wrap: false,
    mapping: true,
  })

  # Back to typing into the shell, like :startinsert in Neovim.
  if term_getstatus(bufnr) =~ 'normal'
    feedkeys('i', 'n')
  endif
enddef

def Close()
  if IsOpen()
    popup_close(winid)
  endif
  winid = 0
enddef

export def New()
  Close()
  const bufnr = term_start(&shell, {
    hidden: true,
    term_finish: 'close',
    term_kill: 'hup',
    norestore: true,
  })
  if bufnr <= 0
    return
  endif
  setbufvar(bufnr, '&buflisted', false)
  Prune()
  buffers->add(bufnr)
  current = len(buffers) - 1
  Open()
enddef

export def Toggle()
  if IsOpen()
    Close()
    return
  endif
  Prune()
  if empty(buffers)
    New()
    return
  endif
  Open()
enddef

def Cycle(step: number)
  Prune()
  if empty(buffers)
    New()
    return
  endif
  current = (current + step + len(buffers)) % len(buffers)
  Close()
  Open()
enddef

export def Next()
  Cycle(1)
enddef

export def Prev()
  Cycle(-1)
enddef

export def Kill()
  Prune()
  if empty(buffers)
    return
  endif
  Close()
  const bufnr = buffers->remove(current)
  if bufexists(bufnr)
    execute $'bwipeout! {bufnr}'
  endif
  if empty(buffers)
    current = 0
    return
  endif
  current = min([current, len(buffers) - 1])
  Open()
enddef

export def KillAll()
  Close()
  for bufnr in buffers
    if bufexists(bufnr)
      execute $'bwipeout! {bufnr}'
    endif
  endfor
  buffers = []
  current = 0
enddef
