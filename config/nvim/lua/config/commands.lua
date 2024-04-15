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
