" Take the indent width from the nearest .clang-format, searching upward from
" the file's directory; 4 when there is none.
"
" Legacy script, like the other ftplugins, so it works in any Vim.
let s:indent_width = 4

let s:file = findfile('.clang-format', '.;~')
if !empty(s:file)
  for s:line in readfile(s:file)
    let s:width = matchstr(s:line, '^\s*IndentWidth:\s*\zs\d\+')
    if !empty(s:width)
      let s:indent_width = str2nr(s:width)
      break
    endif
  endfor
endif

let &l:shiftwidth = s:indent_width
let &l:tabstop = s:indent_width
let &l:softtabstop = s:indent_width
