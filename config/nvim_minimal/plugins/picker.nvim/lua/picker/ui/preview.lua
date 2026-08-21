local M = {}

function M.read_file(path)
	local bufnr = vim.fn.bufnr(path)

	-- Prefer the live Neovim buffer so unsaved changes
	-- are visible in the preview.
	if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

		if #lines == 0 then
			return { "[empty file]" }
		end

		return lines
	end

	-- Otherwise read the file from disk.
	local file = io.open(path, "r")

	if not file then
		return { "Unable to preview file" }
	end

	local lines = {}

	for line in file:lines() do
		lines[#lines + 1] = line
	end

	file:close()

	if #lines == 0 then
		return { "[empty file]" }
	end

	return lines
end

return M
