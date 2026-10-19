vim9script

var winid = 0
var current = 0          # index into `buffers`, valid when it isn't empty
var buffers: list<number> = []

const BORDER = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

def IsOpen(): bool
  return winid > 0 && !empty(popup_getpos(winid))
enddef

def Wipe(bufnr: number)
  if bufexists(bufnr)
    execute $'bwipeout! {bufnr}'
  endif
enddef

# Forget terminals whose shell has exited. Depending on the Vim version and
# whether the popup was showing, the buffer is either wiped or left behind as
# a "finished" terminal, so wipe those too.
def Prune()
  const was = empty(buffers) ? -1 : buffers[current]
  for b in buffers
    if bufexists(b) && term_getstatus(b) =~ 'finished'
      if IsOpen() && winbufnr(winid) == b
        Close()
      endif
      Wipe(b)
    endif
  endfor
  buffers->filter((_, b) => bufexists(b))
  if empty(buffers)
    current = 0
    return
  endif
  const at = index(buffers, was)
  current = at >= 0 ? at : min([current, len(buffers) - 1])
enddef

# A title in the middle of the top border. Vim puts the title at the left,
# so pad it with border characters to push it to the centre.
def Title(text: string, width: number): string
  const left = max([(width - strdisplaywidth(text)) / 2, 0])
  return repeat(BORDER[0], left) .. text
enddef

# Size, position and title, from g:float_term_size and the current screen.
def Layout(): dict<any>
  const size = get(g:, 'float_term_size', 0.75)
  const width = float2nr(&columns * size)
  const height = float2nr(&lines * size)
  return {
    pos: 'center',
    minwidth: width,
    maxwidth: width,
    minheight: height,
    maxheight: height,
    title: Title($' {current + 1}/{len(buffers)} ', width),
  }
enddef

def Resize()
  if IsOpen()
    popup_setoptions(winid, Layout())
  endif
enddef

augroup float_term
  autocmd!
  autocmd VimResized * Resize()
augroup END

def Open()
  Prune()
  if empty(buffers)
    return
  endif
  const bufnr = buffers[current]
  winid = popup_create(bufnr, Layout()->extend({
    border: [],
    borderchars: BORDER,
  }))

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
  const was_open = IsOpen()
  Close()
  Wipe(buffers[current])
  Prune()
  if was_open
    Open()
  endif
enddef

export def KillAll()
  Close()
  for bufnr in buffers
    Wipe(bufnr)
  endfor
  Prune()
enddef
