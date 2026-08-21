local layout = require("picker.ui.layout")
local previewer = require("picker.ui.preview")

local M = {}

function M.open(opts)
	local layout_type = layout.get()

	local total_width = math.floor(vim.o.columns * 0.85)
	local total_height = math.floor(vim.o.lines * 0.75)

	local list_width
	local list_height
	local preview_width
	local preview_height

	if layout_type == "side" then
		list_width = math.floor(total_width * 0.45)
		preview_width = total_width - list_width - 2

		list_height = total_height
		preview_height = total_height
	elseif layout_type == "bottom" then
		list_width = total_width
		preview_width = total_width

		list_height = math.floor(total_height * 0.45)
		preview_height = total_height - list_height - 2
	else
		list_width = total_width
		list_height = total_height

		preview_width = 0
		preview_height = 0
	end

	local row = math.floor((vim.o.lines - total_height) / 2)
	local col = math.floor((vim.o.columns - total_width) / 2)

	--
	-- Results window
	--

	local list_buf = vim.api.nvim_create_buf(false, true)

	local list_win = vim.api.nvim_open_win(list_buf, true, {
		relative = "editor",
		width = list_width,
		height = list_height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " " .. opts.title .. " ",
		title_pos = "center",
	})

	vim.bo[list_buf].buftype = "nofile"
	vim.bo[list_buf].bufhidden = "wipe"
	vim.bo[list_buf].swapfile = false

	vim.wo[list_win].wrap = false
	vim.wo[list_win].cursorline = false

	--
	-- Preview window
	--

	local preview_buf
	local preview_win

	if layout_type ~= "none" then
		preview_buf = vim.api.nvim_create_buf(false, true)

		local preview_row
		local preview_col

		if layout_type == "side" then
			preview_row = row
			preview_col = col + list_width + 2
		else
			preview_row = row + list_height + 2
			preview_col = col
		end

		preview_win = vim.api.nvim_open_win(preview_buf, false, {
			relative = "editor",
			width = preview_width,
			height = preview_height,
			row = preview_row,
			col = preview_col,
			style = "minimal",
			border = "rounded",
			title = " Preview ",
			title_pos = "center",
		})

		vim.bo[preview_buf].buftype = "nofile"
		vim.bo[preview_buf].bufhidden = "wipe"
		vim.bo[preview_buf].swapfile = false

		vim.wo[preview_win].number = true
		vim.wo[preview_win].relativenumber = false
		vim.wo[preview_win].wrap = false
		vim.wo[preview_win].cursorline = true
	end

	--
	-- State
	--

	local query = ""
	local results = opts.initial_results or {}
	local selected = 1
	local scroll_offset = 1

	--
	-- Preview
	--

	local function update_preview()
		if layout_type == "none" then
			return
		end

		if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
			return
		end

		if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
			return
		end

		local result = results[selected]

		vim.bo[preview_buf].modifiable = true

		if not result then
			vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { "No selection" })

			vim.bo[preview_buf].modifiable = false
			return
		end

		local preview = opts.preview(result)

		if not preview or not preview.file then
			vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { "No preview available" })

			vim.bo[preview_buf].modifiable = false
			return
		end

		local lines = previewer.read_file(preview.file)

		vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)

		local ft = vim.filetype.match({
			filename = preview.file,
		})

		if ft then
			vim.bo[preview_buf].filetype = ft
		end

		vim.bo[preview_buf].modifiable = false

		local line_count = vim.api.nvim_buf_line_count(preview_buf)

		local lnum = math.min(preview.lnum or 1, line_count)

		local line = vim.api.nvim_buf_get_lines(preview_buf, lnum - 1, lnum, false)[1] or ""

		local column = math.min(math.max((preview.col or 1) - 1, 0), #line)

		vim.api.nvim_win_set_cursor(preview_win, { lnum, column })

		if preview.lnum then
			vim.api.nvim_win_call(preview_win, function()
				vim.cmd("normal! zz")
			end)
		else
			vim.api.nvim_win_call(preview_win, function()
				vim.cmd("normal! zt")
			end)
		end
	end

	--
	-- Viewport
	--

	local function update_scroll_offset()
		local visible_count = math.max(list_height - 2, 1)

		if #results == 0 then
			scroll_offset = 1
			return
		end

		if selected < scroll_offset then
			scroll_offset = selected
		end

		local last_visible = scroll_offset + visible_count - 1

		if selected > last_visible then
			scroll_offset = selected - visible_count + 1
		end

		local max_offset = math.max(#results - visible_count + 1, 1)

		scroll_offset = math.max(1, math.min(scroll_offset, max_offset))
	end

	--
	-- Render
	--

	local function render()
		if not vim.api.nvim_buf_is_valid(list_buf) then
			return
		end

		if #results == 0 then
			selected = 1
		else
			selected = math.max(1, math.min(selected, #results))
		end

		update_scroll_offset()

		local lines = {
			"> " .. query,
			"",
		}

		local visible_count = math.max(list_height - 2, 1)

		local finish = math.min(#results, scroll_offset + visible_count - 1)

		for i = scroll_offset, finish do
			local prefix = i == selected and "> " or "  "

			lines[#lines + 1] = prefix .. opts.format(results[i])
		end

		vim.bo[list_buf].modifiable = true

		vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, lines)

		vim.bo[list_buf].modifiable = false

		-- The buffer cursor itself should never scroll our synthetic list.
		if vim.api.nvim_win_is_valid(list_win) then
			vim.api.nvim_win_set_cursor(list_win, { 1, 0 })

			vim.api.nvim_win_call(list_win, function()
				vim.cmd("normal! zt")
			end)
		end

		update_preview()
	end

	--
	-- Search
	--

	local function search()
		results = opts.search(query)
		selected = 1
		scroll_offset = 1

		render()
	end

	--
	-- Close
	--

	local function close()
		if preview_win and vim.api.nvim_win_is_valid(preview_win) then
			vim.api.nvim_win_close(preview_win, true)
		end

		if vim.api.nvim_win_is_valid(list_win) then
			vim.api.nvim_win_close(list_win, true)
		end
	end

	--
	-- Open selection
	--

	local function open_selected()
		local result = results[selected]

		if not result then
			return
		end

		close()
		opts.select(result)
	end

	--
	-- Navigation
	--

	local function move_down()
		if #results == 0 then
			return
		end

		selected = selected + 1

		if selected > #results then
			selected = 1
			scroll_offset = 1
		end

		render()
	end

	local function move_up()
		if #results == 0 then
			return
		end

		selected = selected - 1

		if selected < 1 then
			selected = #results

			local visible_count = math.max(list_height - 2, 1)

			scroll_offset = math.max(#results - visible_count + 1, 1)
		end

		render()
	end

	--
	-- Keymaps
	--

	vim.keymap.set("n", "<CR>", open_selected, {
		buffer = list_buf,
		nowait = true,
	})

	vim.keymap.set("n", "<C-n>", move_down, {
		buffer = list_buf,
		nowait = true,
	})

	vim.keymap.set("n", "<C-p>", move_up, {
		buffer = list_buf,
		nowait = true,
	})

	vim.keymap.set("n", "<Down>", move_down, {
		buffer = list_buf,
		nowait = true,
	})

	vim.keymap.set("n", "<Up>", move_up, {
		buffer = list_buf,
		nowait = true,
	})

	vim.keymap.set("n", "<Esc>", close, {
		buffer = list_buf,
		nowait = true,
	})

	vim.keymap.set("n", "<BS>", function()
		if #query == 0 then
			return
		end

		query = query:sub(1, -2)
		search()
	end, {
		buffer = list_buf,
		nowait = true,
	})

	for i = 32, 126 do
		local char = string.char(i)

		vim.keymap.set("n", char, function()
			query = query .. char
			search()
		end, {
			buffer = list_buf,
			nowait = true,
		})
	end

	render()
end

return M
