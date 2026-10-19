vim9script

# The builtin engine (see plugin/completion.vim). yegappan/lsp's own
# completion is switched off; its omnifunc feeds the LSP source instead.

# source name -> its 'complete' flags.
#   lsp     wraps yegappan/lsp's omnifunc (see Lsp() below)
#   buffer  words from this buffer, buffers in other windows and other
#           loaded buffers
#   path    file and directory names (autoload/completion/path.vim)
const FLAGS = {
  path: ['Fcompletion#path#Complete'],
  lsp: ['Fcompletion#builtin#Lsp'],
  buffer: ['.', 'w', 'b'],
}

# g:completion_{name}, or `default`.
def Setting(name: string, default: any): any
  return get(g:, $'completion_{name}', default)
enddef

def CompleteOption(): string
  var flags: list<string> = []
  const max_items = Setting('max_items', {})
  for name in Setting('sources', ['path', 'lsp', 'buffer'])
    if !has_key(FLAGS, name)
      completion#Notify($'unknown source: {name}')
      continue
    endif
    # The limit is per flag: buffer's three flags may add that many each.
    const max = max_items->get(name, 0)
    for flag in FLAGS[name]
      flags->add(max > 0 ? $'{flag}^{max}' : flag)
    endfor
  endfor
  return join(flags, ',')
enddef

def CompleteOpt(): string
  var opts = ['menuone', 'noselect']
  if Setting('fuzzy', true)
    opts->add('fuzzy')
  endif
  if Setting('docs', true)
    opts->add('popup')
  endif
  return join(opts, ',')
enddef

# ---------------------------------------------------------------------------
# LSP source
# ---------------------------------------------------------------------------

# Cut `text` to `width` display columns, ending in "…" when cut.
def Truncate(text: string, width: number): string
  if width <= 0 || strdisplaywidth(text) <= width
    return text
  endif
  # A character is at least one column wide, so this is never too short;
  # only wide characters can leave it too long, and then by a little.
  var cut = strcharpart(text, 0, width - 1)
  while strdisplaywidth(cut) > width - 1
    cut = strcharpart(cut, 0, strchars(cut) - 1)
  endwhile
  return $'{cut}…'
enddef

# Some servers send the same text as both parts of "detail | info": keep
# one. (A regex with a back-reference is quadratic on long details.)
def Dedupe(text: string): string
  const n = len(text)
  if n < 5 || (n - 3) % 2 != 0
    return text
  endif
  const half = (n - 3) / 2
  if strpart(text, half, 3) == ' | ' && strpart(text, 0, half) == strpart(text, half + 3)
    return strpart(text, 0, half)
  endif
  return text
enddef

# The buffer's completion server, when it is up and able to answer.
def LspReady(): bool
  if !exists('g:loaded_lsp') || &omnifunc != 'g:LspOmniFunc'
    return false
  endif
  try
    const server = lsp#buffer#CurbufGetServer('completion')
    return !empty(server) && server.running && server.ready
  catch
    return false
  endtry
enddef

# yegappan/lsp's omnifunc, as a 'complete' source. It skips buffers whose
# server is missing or still starting (the omnifunc would print an error on
# every key), and shortens long items: one long name, like an auto-import
# path, would otherwise widen the whole menu and push the docs off screen.
export def Lsp(findstart: number, base: string): any
  if !LspReady()
    return findstart ? -3 : []
  endif

  if findstart
    const start = g:LspOmniFunc(findstart, base)
    # Vim leaves the source out on both -2 and -3, but after -2 a source
    # that returned {refresh: 'always'} is still asked again as you type.
    return start == -2 ? -3 : start
  endif

  # The omnifunc gives up as soon as complete_check() is true, which during
  # autocompletion is almost at once. Wait for the reply here instead, for
  # up to a second (about what Vim allows function sources; see
  # 'autocompletetimeout'), stopping early when a key is typed.
  const started = reltime()
  while g:LspOmniCompletePending() && reltimefloat(reltime(started)) < 1.0
    if getchar(1) != 0
      return v:none
    endif
    sleep 2m
  endwhile
  var result = g:LspOmniFunc(findstart, base)
  if type(result) != v:t_list
    return result
  endif

  const width = {abbr: 40, menu: 30}->extend(Setting('max_width', {}))
  return result->map((_, item) => item->extend({
    abbr: Truncate(item->get('abbr', item.word), width->get('abbr', 0)),
    menu: Truncate(Dedupe(item->get('menu', '')), width->get('menu', 0)),
  }))
enddef

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

# 'autocompletedelay' came last (9.1.1638), after 'autocomplete' (9.1.1590)
# and autoloaded F{func} sources (9.1.1603).
export def Available(): bool
  return exists('+autocompletedelay') == 1
enddef

export def Setup()
  # Through :execute, so a Vim without these options can still compile it.
  execute $'set autocomplete autocompletedelay={Setting("delay_ms", 0)}'
  &complete = CompleteOption()
  &completeopt = CompleteOpt()
  completion#LspOptions({autoComplete: false, omniComplete: true})
enddef
