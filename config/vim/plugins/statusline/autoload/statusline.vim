vim9script

# 'statusline' is "%!statusline#Render()". Vim evaluates it with the
# window being drawn in g:statusline_winid, so each window is drawn from its
# own buffer.

import autoload './statusline/git.vim'

const DEFAULT_SHOW = {
  mode: true,
  git: true,          # branch
  diff: true,         # +added ~changed -removed against the git index
  diagnostics: true,
  lsp: true,          # progress while a server works, else attached servers
  filetype: true,
  position: true,     # line:column
}

# Nerd Font codicons.
const DEFAULT_ICONS = {
  error: " ",
  warn: " ",
  info: " ",
  hint: " ",
}

var show: dict<bool> = {}
var icons: dict<string> = {}

const MODES = {
  n: 'NORMAL',
  i: 'INSERT',
  v: 'VISUAL',
  V: 'V-LINE',
  "\<C-v>": 'V-BLOCK',
  c: 'COMMAND',
  t: 'TERMINAL',
  R: 'REPLACE',
  s: 'SELECT',
  S: 'S-LINE',
  "\<C-s>": 'S-BLOCK',
}

# ---------------------------------------------------------------------------
# Highlights, built from the colorscheme so they fit whichever is active
# ---------------------------------------------------------------------------

# A color attribute of a group, following links; '' when unset.
def Attr(group: string, key: string): string
  const found = hlget(group, true)
  if empty(found)
    return ''
  endif
  const value = found[0]->get(key, '')
  return value == 'NONE' ? '' : value
enddef

# Define `name` with the foreground of `fg_group` (else Normal's) on the
# background of `bg_group`.
def Derive(name: string, fg_group: string, bg_group: string, bold = false)
  var group: dict<any> = {name: name}
  for kind in ['gui', 'cterm']
    var fg = Attr(fg_group, $'{kind}fg')
    if empty(fg)
      fg = Attr('Normal', $'{kind}fg')
    endif
    const bg = Attr(bg_group, $'{kind}bg')
    if !empty(fg)
      group[$'{kind}fg'] = fg
    endif
    if !empty(bg)
      group[$'{kind}bg'] = bg
    endif
    if bold
      group[kind] = {bold: true}
    endif
  endfor
  hlset([group])
enddef

def Highlights()
  Derive('StlMode', 'PmenuSel', 'Visual', true)
  Derive('StlGit', 'Directory', 'PmenuSel')
  # Vim draws a statusline group without a background on Normal's, not the
  # statusline's, so these carry StatusLine's background.
  Derive('StlAdded', 'Added', 'StatusLine')
  Derive('StlChanged', 'Changed', 'StatusLine')
  Derive('StlRemoved', 'Removed', 'StatusLine')
  Derive('StlError', 'ErrorMsg', 'StatusLine')
  Derive('StlWarn', 'WarningMsg', 'StatusLine')
  Derive('StlInfo', 'Directory', 'StatusLine')
  Derive('StlHint', 'Question', 'StatusLine')
enddef

# ---------------------------------------------------------------------------
# Parts. Each takes the buffer shown in the window being drawn and returns
# statusline text, '' when it has nothing to show.
# ---------------------------------------------------------------------------

# Text from buffers and git: a "%" in it would be read as a statusline item.
def Esc(text: string): string
  return substitute(text, '%', '%%', 'g')
enddef

def Mode(): string
  const m = mode()
  const label = MODES->get(m, MODES->get(m[0], toupper(m)))
  return $'%#StlMode# {label} %*'
enddef

# A file buffer's absolute path, or '' for special and unnamed buffers.
def FilePath(bufnr: number): string
  const name = bufname(bufnr)
  if empty(name) || !empty(getbufvar(bufnr, '&buftype'))
    return ''
  endif
  return fnamemodify(name, ':p')
enddef

def Branch(bufnr: number): string
  const path = FilePath(bufnr)
  const root = empty(path) ? '' : git.Root(path)
  const branch = empty(root) ? '' : git.Branch(root)
  return empty(branch) ? '' : $'%#StlGit# {Esc(branch)} %*'
enddef

def Diff(bufnr: number): string
  const counts = git.Counts(bufnr)
  if empty(counts)
    return ''
  endif
  var out: list<string> = []
  for [n, sign, group] in [
      [counts.added, '+', 'StlAdded'],
      [counts.changed, '~', 'StlChanged'],
      [counts.removed, '-', 'StlRemoved']]
    if n > 0
      out->add($'%#{group}#{sign}{n}%*')
    endif
  endfor
  return join(out, ' ')
enddef

# A terminal's name is "!{command and arguments}"; show "term:" and the
# program instead.
def TerminalName(bufnr: number): string
  const cmd = bufname(bufnr)->substitute('^!', '', '')
  const program = matchstr(cmd, '^\S\+')
  return $'term:{fnamemodify(empty(program) ? cmd : program, ":t")}'
enddef

# The path relative to its repository, else to home; a terminal by its
# program; other special buffers by Vim's own name for them. Then [+] when
# modified, [RO] when read-only (not for terminals).
#
# It starts with %<, so a window too narrow for the whole line cuts the
# start of the path rather than the mode and branch before it.
def Path(bufnr: number): string
  const path = FilePath(bufnr)
  var shown = '%f'
  if !empty(path)
    const root = git.Root(path)
    shown = Esc(empty(root) ? fnamemodify(path, ':~') : strpart(path, len(root) + 1))
  elseif getbufvar(bufnr, '&buftype') == 'terminal'
    # A running terminal is always "modified"; the flags say nothing.
    return $'%<{Esc(TerminalName(bufnr))}'
  endif
  return $'%<{shown}%( %m%r%)'
enddef

def Diagnostics(bufnr: number): string
  if !exists('g:loaded_lsp')
    return ''
  endif
  var counts: dict<number>
  try
    counts = lsp#diag#DiagsGetErrorCount(bufnr)
  catch
    return ''
  endtry
  var out: list<string> = []
  for [key, icon, group] in [
      ['Error', 'error', 'StlError'],
      ['Warn', 'warn', 'StlWarn'],
      ['Info', 'info', 'StlInfo'],
      ['Hint', 'hint', 'StlHint']]
    const n = counts->get(key, 0)
    if n > 0
      out->add($'%#{group}#{icons[icon]}{n}%*')
    endif
  endfor
  return join(out, ' ')
enddef

# "lua_ls: Indexing 40%" while a server works, else "ty, ruff", or "".
def Lsp(bufnr: number): string
  if !exists('g:loaded_lsp')
    return ''
  endif
  var servers: list<dict<any>>
  try
    servers = lsp#buffer#BufLspServersGet(bufnr)
  catch
    return ''
  endtry

  const names = servers->copy()->filter((_, s) => s->get('running', false))->map((_, s) => s.name)
  for p in values(get(g:, 'LspProgress', {}))
    if index(names, p->get('serverName', '')) >= 0
      var text = [p->get('title', ''), p->get('message', '')]
      if p->get('percentage', -1) >= 0
        text->add($'{p.percentage}%')
      endif
      return Esc($'{p.serverName}: {text->filter((_, t) => !empty(t))->join(" ")}')
    endif
  endfor
  return Esc(join(names, ', '))
enddef

def Filetype(bufnr: number): string
  return Esc(getbufvar(bufnr, '&filetype'))
enddef

def Position(): string
  return '%l:%c'
enddef

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

# Join the non-empty pieces with single spaces.
def Join(pieces: list<string>): string
  return pieces->filter((_, p) => !empty(p))->join(' ')
enddef

export def Render(): string
  const win = get(g:, 'statusline_winid', win_getid())
  const bufnr = winbufnr(win)

  if win != win_getid()
    return $' {Path(bufnr)}'
  endif

  const left = Join([
    show.mode ? Mode() : '',
    show.git ? Branch(bufnr) : '',
    show.diff ? Diff(bufnr) : '',
    Path(bufnr),
  ])
  # Server names crowd out the path in a narrow window; leave them out.
  const wide = winwidth(win) >= 80
  const right = Join([
    show.diagnostics ? Diagnostics(bufnr) : '',
    wide && show.lsp ? Lsp(bufnr) : '',
    show.filetype ? Filetype(bufnr) : '',
    show.position ? Position() : '',
  ])
  # The space after %= keeps the sides apart when the path is cut short.
  return $'{left}%= {right} '
enddef

# Redraw every statusline once, however many events asked in one go.
var pending = false
export def Redraw()
  if pending
    return
  endif
  pending = true
  timer_start(0, (_) => {
    pending = false
    redrawstatus!
  })
enddef

export def Setup()
  show = DEFAULT_SHOW->extendnew(get(g:, 'statusline_show', {}))
  icons = DEFAULT_ICONS->extendnew(get(g:, 'statusline_icons', {}))
  Highlights()

  augroup statusline
    autocmd!
    autocmd ColorScheme * Highlights()
    autocmd ModeChanged,FocusGained * Redraw()
    autocmd User LspAttached,LspDetached,LspDiagsUpdated,LspProgressUpdate Redraw()
  augroup END
  git.Setup()

  set laststatus=2
  set statusline=%!statusline#Render()
enddef
