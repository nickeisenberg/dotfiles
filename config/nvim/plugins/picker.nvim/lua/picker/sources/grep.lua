local ui = require("picker.ui")

local M = {}

local MAX_RESULTS = 2000
local PUBLISH_INTERVAL_MS = 40

local function grep_async(query, on_results)
	if query == "" then
		on_results({})
		return function() end
	end

	local job
	local active = true
	local finished = false
	local publish_pending = false
	local tail = ""
	local results = {}

	local function publish()
		if not active then
			return
		end

		-- Give the UI its own list. Result objects remain stable across
		-- publications, allowing the preview to recognize the same selection.
		local snapshot = {}

		for i, result in ipairs(results) do
			snapshot[i] = result
		end

		on_results(snapshot)
	end

	local function publish_later()
		if publish_pending or finished or not active then
			return
		end

		publish_pending = true

		vim.defer_fn(function()
			publish_pending = false

			-- Cancellation or completion makes this queued update unnecessary.
			if active and not finished then
				publish()
			end
		end, PUBLISH_INTERVAL_MS)
	end

	local function consume(line)
		if not active or finished then
			return
		end

		local file, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")

		if not file then
			return
		end

		results[#results + 1] = {
			file = file,
			lnum = tonumber(lnum),
			col = tonumber(col),
			text = text,
		}

		if #results >= MAX_RESULTS then
			finished = true

			-- Stop the underlying process, rather than merely ignoring its output.
			if job and job > 0 then
				pcall(vim.fn.jobstop, job)
			end

			publish()
		end
	end

	job = vim.fn.jobstart({
		"rg",
		"--vimgrep",
		"--color=never",
		"--smart-case",
		"--hidden",
		"--glob",
		"!.git/*",
		"--glob",
		"!node_modules/*",
		"--glob",
		"!dist/*",
		"--glob",
		"!build/*",

		-- End option parsing so a query beginning with "-" is not an rg flag.
		"--",
		query,
		".",
	}, {
		stdout_buffered = false,

		on_stdout = function(_, data)
			if not active or finished or not data then
				return
			end

			-- Job callbacks contain newline-split chunks, not necessarily
			-- complete lines. The first item continues the previous tail;
			-- subsequent items indicate a newline boundary.
			for i, chunk in ipairs(data) do
				if i == 1 then
					tail = tail .. chunk
				else
					consume(tail)

					if finished then
						tail = ""
						return
					end

					tail = chunk
				end
			end

			publish_later()
		end,

		on_exit = function()
			if not active or finished then
				return
			end

			-- Handle output without a trailing newline.
			if tail ~= "" then
				consume(tail)
				tail = ""
			end

			if not finished then
				finished = true
				publish()
			end
		end,
	})

	if job <= 0 then
		active = false

		vim.notify("Unable to start ripgrep. Check that rg is installed.", vim.log.levels.ERROR)

		on_results({})
		return function() end
	end

	-- The picker calls this when the query changes or the picker closes.
	return function()
		if not active then
			return
		end

		active = false

		if not finished then
			finished = true
			pcall(vim.fn.jobstop, job)
		end
	end
end

function M.live_grep()
	ui.open({
		title = "Live Grep",

		search_async = grep_async,

		format = function(result)
			return string.format("%s:%d:%d: %s", result.file, result.lnum, result.col, result.text)
		end,

		preview = function(result)
			return {
				file = result.file,
				lnum = result.lnum,
				col = result.col,
			}
		end,

		select = function(result)
			vim.cmd.edit(vim.fn.fnameescape(result.file))

			local line_count = vim.api.nvim_buf_line_count(0)

			local lnum = math.min(result.lnum, line_count)

			local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""

			local column = math.min(math.max(result.col - 1, 0), #line)

			vim.api.nvim_win_set_cursor(0, { lnum, column })

			vim.cmd("normal! zz")
		end,
	})
end

return M
