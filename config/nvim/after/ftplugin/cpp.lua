local function set_indent_from_clang_format()
  -- Search upward from current file’s dir for .clang-format
  local file = vim.fn.findfile(".clang-format", ".;~")

  local indent_width = 4

  if file ~= "" then
    for line in io.lines(file) do
      local width = line:match("^%s*IndentWidth:%s*(%d+)")
      if width then
        indent_width = tonumber(width) or 4
        break
      end
    end
  end

  -- Apply indent settings
  vim.bo.shiftwidth = indent_width
  vim.bo.tabstop = indent_width
  vim.bo.softtabstop = indent_width
end

set_indent_from_clang_format()
