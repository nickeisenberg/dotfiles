vim9script

# The picker window: a prompt and result list in one popup, a preview of
# the selected result in another.
#
# Open() takes:
#   title            shown in the list's border
#   initial_results  results before anything is typed (optional)
#   search           func(query): list, for sources that filter in Vim
#   search_async     func(query, OnResults): func, for sources that stream
#                    results; it calls OnResults(list) as they arrive and
#                    returns a function that cancels the search
#   format           func(item): string, the text shown for a result
#   preview          func(item): dict, {file, lnum, col} (lnum/col optional)
#   select           func(item), run on <CR> after the picker closes

import autoload './preview.vim'

const SEARCH_DEBOUNCE_MS = 80
const PREVIEW_DEBOUNCE_MS = 60
const SIDE_PREVIEW_MIN_COLUMNS = 120
const BOTTOM_PREVIEW_MIN_LINES = 35
const BORDER = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']

if empty(prop_type_get('PickerSelected'))
  prop_type_add('PickerSelected', {highlight: 'PmenuSel'})
endif
# The prompt's cursor: the real one stays in the window behind the popup.
hlset([{name: 'PickerCursor', default: true, cterm: {reverse: true}, gui: {reverse: true}}])
if empty(prop_type_get('PickerCursor'))
  prop_type_add('PickerCursor', {highlight: 'PickerCursor'})
endif

# Everything about the open picker; {} when none is open.
var p: dict<any> = {}

def Layout(): string
  if &columns >= SIDE_PREVIEW_MIN_COLUMNS
    return 'side'
  endif
  if &lines >= BOTTOM_PREVIEW_MIN_LINES
    return 'bottom'
  endif
  return 'none'
enddef

# A title in the middle of the top border.
def Title(text: string, width: number): string
  const left = max([(width - strchars(text)) / 2, 0])
  return repeat(BORDER[0], left) .. text
enddef

def IsOpen(): bool
  return !empty(p) && !p.closed
enddef

def VisibleCount(): number
  return max([p.list_height - 2, 1])
enddef

# ---------------------------------------------------------------------------
# Preview
# ---------------------------------------------------------------------------

def UpdatePreview()
  if !IsOpen() || p.preview_win == 0
    return
  endif

  const result = get(p.results, p.selected, null)
  const target = result == null ? {} : p.opts.preview(result)
  const win = p.preview_win

  if empty(target) || !has_key(target, 'file')
    # A message replaces the cached file contents.
    p.preview_file = ''
    p.preview_tick = -1
    popup_settext(win, [result == null ? 'No selection' : 'No preview available'])
    win_execute(win, 'setlocal syntax=OFF')
    popup_setoptions(win, {firstline: 1})
    return
  endif

  const file = target.file
  const bufnr = bufnr(file)
  # A loaded buffer can hold unsaved changes; its changedtick says whether
  # the cached preview is stale.
  const tick = bufnr > 0 && bufloaded(bufnr) ? getbufvar(bufnr, 'changedtick') : -1

  if p.preview_file != file || p.preview_tick != tick
    popup_settext(win, preview.ReadFile(file))
    preview.Highlight(win, file)
    p.preview_file = file
    p.preview_tick = tick
  endif

  # Moving between matches in the same file only moves the cursor; it does
  # not reread and rewrite the file.
  const count = line('$', win)
  const lnum = max([1, min([target->get('lnum', 1), count])])
  const col = max([target->get('col', 1), 1])
  win_execute(win, $'call cursor({lnum}, {col})')
  # Centre a match; show a file from the top.
  const firstline = has_key(target, 'lnum') ? max([1, lnum - p.preview_height / 2]) : 1
  popup_setoptions(win, {firstline: firstline})
enddef

def SchedulePreview()
  if p.preview_win == 0
    return
  endif
  const result = get(p.results, p.selected, null)
  # Streaming sources keep result objects stable between batches; a new
  # batch need not refresh an unchanged selection.
  if result is p.requested_preview && p.preview_requested
    return
  endif
  p.requested_preview = result
  p.preview_requested = true
  timer_stop(p.preview_timer)
  p.preview_timer = timer_start(PREVIEW_DEBOUNCE_MS, (_) => UpdatePreview())
enddef

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def UpdateScroll()
  const visible = VisibleCount()
  if empty(p.results)
    p.offset = 0
    return
  endif
  if p.selected < p.offset
    p.offset = p.selected
  endif
  if p.selected > p.offset + visible - 1
    p.offset = p.selected - visible + 1
  endif
  p.offset = max([0, min([p.offset, len(p.results) - visible])])
enddef

def Render()
  if !IsOpen()
    return
  endif
  p.selected = empty(p.results) ? 0 : max([0, min([p.selected, len(p.results) - 1])])
  UpdateScroll()

  const prompt = $'> {p.query}'
  var lines: list<dict<any>> = [
    {text: $'{prompt} ', props: [{col: len(prompt) + 1, length: 1, type: 'PickerCursor'}]},
    {text: ''},
  ]
  # Only format the visible part of the result list.
  const last = min([len(p.results), p.offset + VisibleCount()]) - 1
  for i in range(p.offset, last)
    const text = (i == p.selected ? '> ' : '  ') .. p.opts.format(p.results[i])
    lines->add(i == p.selected
      ? {text: text, props: [{col: 1, length: len(text), type: 'PickerSelected'}]}
      : {text: text})
  endfor
  popup_settext(p.list_win, lines)
  SchedulePreview()
enddef

# ---------------------------------------------------------------------------
# Searching
# ---------------------------------------------------------------------------

def CancelSearch()
  if p.Cancel != null
    const Cancel = p.Cancel
    p.Cancel = null
    Cancel()
  endif
enddef

def Search()
  if !IsOpen()
    return
  endif
  p.generation += 1
  const generation = p.generation
  const query = p.query

  # Stop obsolete work at once, before the debounce delay.
  CancelSearch()
  timer_stop(p.search_timer)

  if empty(query)
    p.results = p.opts->has_key('search') ? p.opts.search('') : []
    p.selected = 0
    p.offset = 0
    Render()
    return
  endif

  # Clear stale matches so <CR> can't open a previous query's result.
  if p.opts->has_key('search_async')
    p.results = []
    p.selected = 0
    p.offset = 0
    Render()
  endif

  p.search_timer = timer_start(SEARCH_DEBOUNCE_MS, (_) => {
    if !IsOpen() || generation != p.generation
      return
    endif
    if p.opts->has_key('search_async')
      p.Cancel = p.opts.search_async(query, (results) => {
        # A stopped job can still have callbacks queued; only the
        # current query may update the picker.
        if !IsOpen() || generation != p.generation
          return
        endif
        p.results = results
        Render()
      })
    else
      p.results = p.opts.search(query)
      p.selected = 0
      p.offset = 0
      Render()
    endif
  })
enddef

# ---------------------------------------------------------------------------
# Closing
# ---------------------------------------------------------------------------

def StopWork()
  if empty(p) || p.closed
    return
  endif
  p.closed = true
  p.generation += 1
  timer_stop(p.search_timer)
  timer_stop(p.preview_timer)
  CancelSearch()
enddef

def Close()
  StopWork()
  if empty(p)
    return
  endif
  const [list_win, preview_win] = [p.list_win, p.preview_win]
  if preview_win != 0
    popup_close(preview_win)
  endif
  popup_close(list_win)
enddef

def OpenSelected()
  const result = get(p.results, p.selected, null)
  if result == null
    return
  endif
  const Select = p.opts.select
  Close()
  # Out of the popup filter, which may not change buffers.
  timer_start(0, (_) => Select(result))
enddef

# ---------------------------------------------------------------------------
# Keys
# ---------------------------------------------------------------------------

def Move(step: number)
  const n = len(p.results)
  if n == 0
    return
  endif
  p.selected = (p.selected + step + n) % n
  Render()
enddef

def Filter(_: number, key: string): bool
  if !IsOpen()
    return false
  endif

  if key == "\<Esc>" || key == "\<C-c>"
    Close()
  elseif key == "\<CR>"
    OpenSelected()
  elseif key == "\<C-n>" || key == "\<Down>"
    Move(1)
  elseif key == "\<C-p>" || key == "\<Up>"
    Move(-1)
  elseif key == "\<BS>" || key == "\<C-h>"
    if !empty(p.query)
      p.query = p.query->strcharpart(0, strchars(p.query) - 1)
      Search()
    endif
  elseif key == "\<C-u>"
    if !empty(p.query)
      p.query = ''
      Search()
    endif
  elseif key == "\<C-w>"
    if !empty(p.query)
      p.query = p.query->substitute('\s*\S*$', '', '')
      Search()
    endif
  elseif strchars(key) == 1 && key[0] != "\x80" && key =~ '^[^[:cntrl:]]$'
    p.query ..= key
    Search()
  endif
  # Every other key is swallowed so it can't act on the buffer behind.
  return true
enddef

# ---------------------------------------------------------------------------

export def Open(opts: dict<any>)
  if IsOpen()
    Close()
  endif

  const layout = Layout()
  const total_width = &columns * 85 / 100
  const total_height = &lines * 75 / 100

  var list_width = total_width
  var list_height = total_height
  var preview_width = 0
  var preview_height = 0
  if layout == 'side'
    list_width = total_width * 45 / 100
    preview_width = total_width - list_width - 2
    preview_height = total_height
  elseif layout == 'bottom'
    list_height = total_height * 45 / 100
    preview_width = total_width
    preview_height = total_height - list_height - 2
  endif

  const row = (&lines - total_height) / 2
  const col = (&columns - total_width) / 2
  const title = $' {opts->get("title", "Picker")} '

  const list_win = popup_create('', {
    line: row + 1,
    col: col + 1,
    minwidth: list_width,
    maxwidth: list_width,
    minheight: list_height,
    maxheight: list_height,
    border: [],
    borderchars: BORDER,
    title: Title(title, list_width),
    wrap: false,
    scrollbar: false,
    mapping: false,
    filter: Filter,
    callback: (_, _) => StopWork(),
    zindex: 200,
  })

  var preview_win = 0
  if layout != 'none'
    preview_win = popup_create('', {
      line: layout == 'side' ? row + 1 : row + list_height + 3,
      col: layout == 'side' ? col + list_width + 3 : col + 1,
      minwidth: preview_width,
      maxwidth: preview_width,
      minheight: preview_height,
      maxheight: preview_height,
      border: [],
      borderchars: BORDER,
      title: Title(' Preview ', preview_width),
      wrap: false,
      scrollbar: false,
      cursorline: true,
      zindex: 200,
    })
    win_execute(preview_win, 'setlocal number norelativenumber')
  endif

  p = {
    opts: opts,
    closed: false,
    query: '',
    results: opts->get('initial_results', []),
    selected: 0,
    offset: 0,
    list_win: list_win,
    preview_win: preview_win,
    list_height: list_height,
    preview_height: preview_height,
    generation: 0,
    Cancel: null,
    search_timer: -1,
    preview_timer: -1,
    preview_file: '',
    preview_tick: -1,
    requested_preview: null,
    preview_requested: false,
  }
  Render()
enddef
