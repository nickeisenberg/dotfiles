vim9script

# LSP references and definitions in the picker.
#
# Requests go through yegappan/lsp's documented server API
# (|lsp-custom-requests|): lsp.Server() for the buffer's server, and its
# rpc_a() to ask asynchronously.

import autoload 'lsp/lsp.vim' as yegappan
import autoload './ui.vim'

def Notify(msg: string, error = false)
  if error
    echohl ErrorMsg
  endif
  echomsg $'picker: {msg}'
  if error
    echohl None
  endif
enddef

# "file:///a/b%20c" -> "/a/b c". Percent-escapes are bytes ("%C3%A4" is
# "ä"): each becomes a "\x.." escape in a double-quoted string, which
# keeps multibyte names intact.
def UriToFile(uri: string): string
  if uri !~ '^file://'
    return uri
  endif
  const path = uri[7 :]
  if stridx(path, '%') < 0
    return path
  endif
  const quoted = path->escape('\"')->substitute('%\(\x\x\)', '\\x\1', 'g')
  return eval($'"{quoted}"')
enddef

# The text of line `lnum` of `file`, from the buffer when it is loaded.
def LineText(file: string, lnum: number): string
  const bufnr = bufnr(file)
  if bufnr > 0 && bufloaded(bufnr)
    return get(getbufline(bufnr, lnum), 0, '')
  endif
  if !filereadable(file)
    return ''
  endif
  return get(readfile(file, '', lnum), lnum - 1, '')
enddef

def ToItem(location: dict<any>): dict<any>
  const uri = location->get('uri', location->get('targetUri', ''))
  const range = location->get('range', location->get('targetSelectionRange', {}))
  if empty(uri) || empty(range)
    return {}
  endif

  const file = UriToFile(uri)
  const lnum = range.start.line + 1
  const line = LineText(file, lnum)
  # LSP columns count characters; Vim's count bytes.
  const byte = byteidx(line, range.start.character)
  const col = (byte < 0 ? range.start.character : byte) + 1
  const text = trim(line)

  return {
    display: printf('%s:%d:%d: %s', fnamemodify(file, ':.'), lnum, col, text),
    file: file,
    lnum: lnum,
    col: col,
  }
enddef

def OpenItem(item: dict<any>)
  execute 'edit' fnameescape(item.file)
  cursor(min([item.lnum, line('$')]), item.col)
  normal! zz
enddef

def OpenLocations(title: string, items: list<dict<any>>)
  items->sort((a, b) => a.file != b.file
    ? (a.file < b.file ? -1 : 1)
    : a.lnum != b.lnum ? a.lnum - b.lnum : a.col - b.col)

  ui.Open({
    title: title,
    initial_results: items,
    # Through call(): Vim 9.0 types matchfuzzy() as returning strings even
    # for a list of dicts, so a direct call fails to compile there.
    search: (query) => empty(query) ? items : call('matchfuzzy', [items, query, {key: 'display'}]),
    format: (item) => item.display,
    preview: (item) => ({file: item.file, lnum: item.lnum, col: item.col}),
    select: OpenItem,
  })
enddef

# Ask the buffer's server for `method` at the cursor and show the locations
# in a picker titled `title`.
def Request(method: string, feature: string, title: string, extra: dict<any> = {})
  if !exists('g:loaded_lsp')
    Notify('yegappan/lsp is not loaded', true)
    return
  endif
  const server = yegappan.Server()
  if empty(server) || !server.featureEnabled(feature)
    Notify($'no language server for {title->tolower()} here')
    return
  endif

  # Send pending edits first, so positions match the buffer.
  listener_flush()
  const params = server.getTextDocPosition(true)->extend(extra)
  const what = title->tolower()

  # The callback gets (server, result) or (server, result, error)
  # depending on the yegappan/lsp version.
  server.rpc_a(method, params, (_, result, ...rest) => {
    try
      Show(title, result, get(rest, 0, {}))
    catch
      # yegappan/lsp swallows errors raised in callbacks; report them.
      Notify($'{what}: {v:exception}', true)
    endtry
  })
enddef

def Show(title: string, result: any, error: dict<any>)
  const what = title->tolower()
  if !empty(error)
    Notify($'{what} failed: {error->get("message", string(error))}', true)
    return
  endif

  var locations: list<any> = []
  if type(result) == v:t_list
    locations = result
  elseif type(result) == v:t_dict && !empty(result)
    # A single Location or LocationLink instead of a list.
    locations = [result]
  endif

  var items = locations->mapnew((_, l) => ToItem(l))->filter((_, i) => !empty(i))
  if empty(items)
    Notify($'no {what} found')
    return
  endif
  OpenLocations(title, items)
enddef

export def References()
  Request('textDocument/references', 'references', 'References',
    {context: {includeDeclaration: true}})
enddef

export def Definitions()
  Request('textDocument/definition', 'definition', 'Definitions')
enddef
