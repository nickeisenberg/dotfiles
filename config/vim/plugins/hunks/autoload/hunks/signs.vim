vim9script

# Hunks as signs in the sign column:
#
#   add           lines added
#   change        lines changed
#   delete        lines removed below this line
#   topdelete     lines removed above line 1
#   changedelete  changed, and lines removed below it
#
# The text of each can be set with g:hunks_signs, e.g. {add: '┃'}, and the
# priority with g:hunks_priority (default 5, below diagnostics' signs).

const GROUP = 'hunks'

const DEFAULT_TEXT = {
  add: '+',
  change: '~',
  delete: '_',
  topdelete: '‾',
  changedelete: '~_',
}

const NAMES = {
  add: 'HunksAdd',
  change: 'HunksChange',
  delete: 'HunksDelete',
  topdelete: 'HunksTopDelete',
  changedelete: 'HunksChangeDelete',
}

# A color attribute of a group, following links; '' when unset.
def Attr(group: string, key: string): string
  const found = hlget(group, true)
  if empty(found)
    return ''
  endif
  const value = found[0]->get(key, '')
  return value == 'NONE' ? '' : value
enddef

# `name` links to `group` when the colorscheme has it (Added, Changed and
# Removed are newer than 9.0), else it takes its color from the background
# of the diff-mode group, which every colorscheme sets.
def Color(name: string, group: string, diff_group: string)
  if hlexists(group)
    execute $'highlight default link {name} {group}'
    return
  endif
  var attrs: list<string> = []
  const gui = Attr(diff_group, 'guibg')
  const cterm = Attr(diff_group, 'ctermbg')
  if !empty(gui)
    attrs->add($'guifg={gui}')
  endif
  if !empty(cterm)
    attrs->add($'ctermfg={cterm}')
  endif
  if empty(attrs)
    execute $'highlight default link {name} {diff_group}'
  else
    execute $'highlight default {name} {join(attrs)}'
  endif
enddef

# Run again on ColorScheme: a colorscheme clears the groups.
export def Highlights()
  Color('HunksAdd', 'Added', 'DiffAdd')
  Color('HunksChange', 'Changed', 'DiffChange')
  Color('HunksDelete', 'Removed', 'DiffDelete')
  highlight default link HunksTopDelete HunksDelete
  highlight default link HunksChangeDelete HunksChange
enddef

export def Define()
  Highlights()
  const text = extendnew(DEFAULT_TEXT, get(g:, 'hunks_signs', {}))
  for [kind, name] in items(NAMES)
    sign_define(name, {text: text[kind], texthl: name})
  endfor
enddef

# The signs for a list of hunks: [{lnum, kind}], in line order.
export def ForHunks(hunks: list<dict<number>>): list<dict<any>>
  var signs: list<dict<any>> = []
  for h in hunks
    if h.old_count == 0
      for i in range(h.new_count)
        signs->add({lnum: h.new_start + 1 + i, kind: 'add'})
      endfor
    elseif h.new_count == 0
      signs->add(h.new_start == 0
        ? {lnum: 1, kind: 'topdelete'}
        : {lnum: h.new_start, kind: 'delete'})
    else
      const changed = min([h.old_count, h.new_count])
      for i in range(changed)
        signs->add({lnum: h.new_start + 1 + i, kind: 'change'})
      endfor
      for i in range(changed, h.new_count - 1)
        signs->add({lnum: h.new_start + 1 + i, kind: 'add'})
      endfor
      if h.old_count > h.new_count
        signs[-1].kind = 'changedelete'
      endif
    endif
  endfor
  return signs
enddef

export def Place(bufnr: number, hunks: list<dict<number>>)
  Clear(bufnr)
  const priority = get(g:, 'hunks_priority', 5)
  sign_placelist(ForHunks(hunks)->mapnew((_, s) => ({
    buffer: bufnr,
    group: GROUP,
    lnum: s.lnum,
    name: NAMES[s.kind],
    priority: priority,
  })))
enddef

export def Clear(bufnr: number)
  if bufexists(bufnr)
    sign_unplace(GROUP, {buffer: bufnr})
  endif
enddef

# The kinds of the signs placed in a buffer, by line: {lnum: kind}. For the
# tests.
export def Placed(bufnr: number): dict<string>
  var by_name: dict<string> = {}
  for [kind, name] in items(NAMES)
    by_name[name] = kind
  endfor
  var placed: dict<string> = {}
  for s in sign_getplaced(bufnr, {group: GROUP})[0].signs
    placed[string(s.lnum)] = by_name[s.name]
  endfor
  return placed
enddef
