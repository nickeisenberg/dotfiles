vim9script

# Path source: completes file and directory names once the text before the
# cursor contains a "/".
#
# Complete() follows the 'completefunc' protocol (|complete-functions|), so
# it can sit in 'complete' as an F{func} source.

# Quotes, whitespace and brackets end a path.
const PATH_TOKEN = '[^ \t"''`()[\]{}<>]*/[^ \t"''`()[\]{}<>/]*$'

def Opt(name: string, default: any): any
  return get(g:, 'completion_path', {})->get(name, default)
enddef

# Turn the typed directory ("~/x/", "./x/", "x/", "/x/") into one that can
# be scanned. The typed form is kept for the inserted text.
def Resolve(dir: string): string
  if dir =~ '^[~$]'
    return expand(dir)
  endif
  if dir[0] == '/'
    return dir
  endif

  var base = ''
  if Opt('relative_to', 'buffer') == 'buffer' && !empty(bufname())
    base = expand('%:p:h')
  endif
  return $'{empty(base) ? getcwd() : base}/{dir}'
enddef

def Scan(dir: string, prefix: string): list<dict<any>>
  const path = Resolve(dir)
  if !isdirectory(path)
    return []
  endif

  const show_hidden = Opt('hidden', true) || prefix[0] == '.'
  var entries = readdirex(path, (e) => show_hidden || e.name[0] != '.', {sort: 'none'})
    ->map((_, e) => ({name: e.name, is_dir: e.type == 'dir' || e.type == 'linkd'}))

  # Directories first, then by name.
  return entries->sort((a, b) => a.is_dir != b.is_dir
    ? (a.is_dir ? -1 : 1)
    : (a.name < b.name ? -1 : a.name > b.name ? 1 : 0))
enddef

def Matches(entries: list<dict<any>>, prefix: string): list<dict<any>>
  if empty(prefix)
    return entries
  endif
  if get(g:, 'completion_fuzzy', true)
    # Through call(): Vim 9.0 types matchfuzzy() as returning strings even
    # for a list of dicts, so a direct call fails to compile there.
    return call('matchfuzzy', [entries, prefix, {key: 'name'}])
  endif
  return entries->filter((_, e) => e.name->stridx(prefix) == 0)
enddef

export def Complete(findstart: number, base: string): any
  if findstart
    const line = getline('.')->strpart(0, col('.') - 1)
    const token = matchstr(line, PATH_TOKEN)
    # -3: not a path here; leave this source out.
    return empty(token) ? -3 : len(line) - len(token)
  endif

  const parts = matchlist(base, '^\(.*/\)\([^/]*\)$')
  if empty(parts)
    return []
  endif
  const [dir, prefix] = parts[1 : 2]

  return Matches(Scan(dir, prefix), prefix)->mapnew((_, e) => ({
    word: dir .. e.name,
    abbr: e.name .. (e.is_dir ? '/' : ''),
    kind: e.is_dir ? 'Folder' : 'File',
    menu: '[path]',
  }))
enddef
