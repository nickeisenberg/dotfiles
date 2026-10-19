vim9script

# Path source: completes file and directory names once the text before the
# cursor has a directory part: "x/", "./x/", "~/", "$HOME/", "/usr/". A "/"
# with nothing path-like before it ("</" in HTML, "//" comments, "a / b") is
# left alone, so the root is listed only from "/x/" on, not after "/".
#
# Complete() follows the 'completefunc' protocol (|complete-functions|), so
# it can sit in 'complete' as an F{func} source.

# Quotes, whitespace, brackets, "=", ":" and "," end a path, so
# "--file=./x/", "PATH=~/" and "f(a,./x/" complete. The last "/" must follow
# a character that is neither a "/" nor one of these.
const STOP = ' \t"''`()[\]{}<>=:,'
const PATH_TOKEN = $'[^{STOP}]*[^{STOP}/]/[^{STOP}/]*$'

# A key of g:completion_path.
def PathOpt(name: string, default: any): any
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
  if PathOpt('relative_to', 'buffer') == 'buffer' && !empty(bufname())
    base = expand('%:p:h')
  endif
  return $'{empty(base) ? getcwd() : base}/{dir}'
enddef

# The last directory read, so typing a name doesn't re-read it on every key.
# Cleared on entering Insert mode, to pick up files made since.
var cache = {path: '', entries: []}
augroup completion_path
  autocmd!
  autocmd InsertEnter * cache = {path: '', entries: []}
augroup END

# Directories first, then regular names before dotfiles, then by name.
def Order(a: dict<any>, b: dict<any>): number
  if a.is_dir != b.is_dir
    return a.is_dir ? -1 : 1
  endif
  const a_dot = a.name[0] == '.'
  if a_dot != (b.name[0] == '.')
    return a_dot ? 1 : -1
  endif
  return a.name < b.name ? -1 : a.name > b.name ? 1 : 0
enddef

def Scan(dir: string, prefix: string): list<dict<any>>
  const path = Resolve(dir)
  if path != cache.path
    if !isdirectory(path)
      return []
    endif
    cache = {
      path: path,
      entries: readdirex(path, (_) => true, {sort: 'none'})
        ->map((_, e) => ({name: e.name, is_dir: e.type == 'dir' || e.type == 'linkd'}))
        ->sort(Order),
    }
  endif

  if PathOpt('hidden', true) || prefix[0] == '.'
    return copy(cache.entries)
  endif
  return cache.entries->copy()->filter((_, e) => e.name[0] != '.')
enddef

def Matches(entries: list<dict<any>>, prefix: string): list<dict<any>>
  if empty(prefix)
    return entries
  endif
  # The same g:completion_fuzzy as the menu's own matching. Fuzzy results
  # come best match first, not directories first.
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
