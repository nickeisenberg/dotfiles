local function show_cmd_in_float(cmd)
  local output = vim.fn.execute(cmd)

  -- Create a buffer for the floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local output_lines = vim.split(output, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)

  local max_line_len = 0
  for _, line in ipairs(output_lines) do
    max_line_len = math.max(max_line_len, #line)
  end

  local width = max_line_len
  local height = #output_lines
  local win_width = vim.api.nvim_get_option("columns")

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = win_width - width,
    row = 0,
    anchor = "NW",
    style = "minimal"
  }

  -- Create the floating window with the buffer
  vim.api.nvim_open_win(buf, true, opts)
end

vim.api.nvim_create_user_command('ShowCmdInFloat', function(opts)
  show_cmd_in_float(opts.args)
end, { nargs = 1, complete = "command", desc = "Show command output in a floating window" })


local function get_lines_from_current_buffer()
  local result  = {}
  local buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

  local exceptions = { "elif", "else", "except", "finally", "#" }
  local function startsWithException(s)
    for _, exception in ipairs(exceptions) do
      local pattern0 = "^" .. exception .. "[%s:]"
      local pattern1 = "^" .. exception .. "$"
      if string.match(s, pattern0) or string.match(s, pattern1) then
        return true
      end
    end
    return false
  end

  local indent_open = false

  for i, line in pairs(lines) do
    if string.len(line) > 0 and string.match(line, "^%s") ~= nil then
      indent_open = true
    end

    table.insert(result, line)

    if i < #lines then
      if indent_open and string.len(lines[i + 1]) > 0 then
        if string.match(lines[i + 1], "^%s") == nil and not startsWithException(lines[i + 1]) then
          indent_open = false
          table.insert(result, "cr")
        end
      end
    end
  end

  table.insert(result, "cr")
  return result
end


local function display_lines_in_floating_window()
  local lines = get_lines_from_current_buffer()   -- Call the function here
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  -- Calculate the window size and position
  local win_height = math.ceil(height * 0.8)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2)
  local col = math.ceil((width - win_width) / 2)

  -- Create a buffer for the floating window
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set lines to the buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Floating window options
  local opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded'
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Make the floating window enterable
  vim.api.nvim_set_current_win(win)
end


vim.api.nvim_create_user_command('OpenUp', function()
  display_lines_in_floating_window()
end, { nargs = '?' })
