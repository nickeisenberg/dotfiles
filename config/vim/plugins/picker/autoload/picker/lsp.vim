vim9script

# LSP references and definitions in the picker.
#
# Requests go through yegappan/lsp's server API (|lsp-custom-requests|):
# the buffer's server that supports the request, and its rpc_a() to ask
# asynchronously. lsp.Server() would give the buffer's first server even
# when another one is the one that supports the request, so the server
# comes from lsp/buffer.vim, which lsp.Server() itself uses.

import autoload 'lsp/buffer.vim' as yegappan_buffer
import autoload './ui.vim'
import autoload './util.vim'

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
# `cache` keeps each file's lines, so a file is read once for all its
# results.
def LineText(file: string, lnum: number, cache: dict<list<string>>): string
  if !cache->has_key(file)
    const bufnr = util.LoadedBuffer(file)
    cache[file] = bufnr > 0 ? getbufline(bufnr, 1, '$')
      : filereadable(file) ? readfile(file) : []
  endif
  return get(cache[file], lnum - 1, '')
enddef

# The byte index in `line` of LSP position `character`, which counts in
# the server's negotiated encoding: bytes (8), UTF-16 units (16) or
# characters (32).
def ByteIndex(line: string, character: number, encoding: number): number
  if encoding == 8
    return character
  endif
  var byte = -1
  # Vim 9.0 has no UTF-16 byteidx(); counting characters is right for
  # most text.
  if has('patch-9.0.1629')
    byte = byteidx(line, character, encoding == 16)
  else
    byte = byteidx(line, character)
  endif
  return byte < 0 ? character : byte
enddef

def ToItem(location: dict<any>, encoding: number, cache: dict<list<string>>): dict<any>
  const uri = location->get('uri', location->get('targetUri', ''))
  const range = location->get('range', location->get('targetSelectionRange', {}))
  if empty(uri) || empty(range)
    return {}
  endif

  const file = UriToFile(uri)
  const lnum = range.start.line + 1
  const line = LineText(file, lnum, cache)
  const col = ByteIndex(line, range.start.character, encoding) + 1

  return {
    display: util.LocationText(fnamemodify(file, ':.'), lnum, col, trim(line)),
    file: file,
    lnum: lnum,
    col: col,
  }
enddef

def OpenLocations(title: string, items: list<dict<any>>)
  items->sort((a, b) => a.file != b.file
    ? (a.file < b.file ? -1 : 1)
    : a.lnum != b.lnum ? a.lnum - b.lnum : a.col - b.col)

  ui.Open({
    title: title,
    initial_results: items,
    search: (query) => empty(query) ? items : util.FuzzyByKey(items, query, 'display'),
    format: (item) => item.display,
    preview: (item) => ({file: item.file, lnum: item.lnum, col: item.col}),
    select: util.OpenLocation,
  })
enddef

# Ask the buffer's server for `method` at the cursor and show the locations
# in a picker titled `title`.
def Request(method: string, feature: string, title: string, extra: dict<any> = {})
  const what = title->tolower()
  if !exists('g:loaded_lsp')
    util.Notify('yegappan/lsp is not loaded', true)
    return
  endif
  # The buffer's ready server that supports `feature`.
  const server = yegappan_buffer.CurbufGetServer(feature)
  if empty(server) || !server.featureEnabled(feature)
    util.Notify($'no language server for {what} here')
    return
  endif

  # Send pending edits first, so positions match the buffer.
  listener_flush()
  const params = server.getTextDocPosition(true)->extend(extra)
  # A reply that comes after another picker was opened is dropped, rather
  # than replacing that picker.
  const open_count = ui.OpenCount()

  # The callback gets (server, result) or (server, result, error)
  # depending on the yegappan/lsp version.
  const id = server.rpc_a(method, params, (srv, result, ...rest) => {
    # yegappan/lsp has reported the error already (and stays quiet about
    # a cancelled request).
    if !empty(get(rest, 0, {})) || ui.OpenCount() != open_count
      return
    endif
    try
      Show(title, result, srv->get('posEncoding', 32))
    catch
      # yegappan/lsp swallows errors raised in callbacks; report them.
      util.Notify($'{what}: {v:exception}', true)
    endtry
  })
  if id < 0
    util.Notify($'the language server for {what} is not running', true)
  endif
enddef

def Show(title: string, result: any, encoding: number)
  const what = title->tolower()

  var locations: list<any> = []
  if type(result) == v:t_list
    locations = result
  elseif type(result) == v:t_dict && !empty(result)
    # A single Location or LocationLink instead of a list.
    locations = [result]
  endif

  var cache: dict<list<string>> = {}
  var items = locations->mapnew((_, l) => ToItem(l, encoding, cache))->filter((_, i) => !empty(i))
  if empty(items)
    util.Notify($'no {what} found')
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
