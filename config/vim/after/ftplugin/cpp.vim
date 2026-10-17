vim9script

# Take the indent width from the nearest .clang-format, searching upward from
# the file's directory; 4 when there is none.
var indent_width = 4

const file = findfile('.clang-format', '.;~')
if !empty(file)
  for line in readfile(file)
    const width = matchstr(line, '^\s*IndentWidth:\s*\zs\d\+')
    if !empty(width)
      indent_width = str2nr(width)
      break
    endif
  endfor
endif

&l:shiftwidth = indent_width
&l:tabstop = indent_width
&l:softtabstop = indent_width
