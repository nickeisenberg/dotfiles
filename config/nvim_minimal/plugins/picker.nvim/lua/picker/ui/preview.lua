local M = {}

-- Bound preview reads so large files do not get loaded in full.
local MAX_BYTES = 256 * 1024

function M.read_file(path)
	local bufnr = vim.fn.bufnr(path)

	-- Prefer the loaded buffer so unsaved edits appear in the preview.
	if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
		local line_count = vim.api.nvim_buf_line_count(bufnr)

		-- The offset just past the final line gives the buffer's byte size
		-- without first copying its contents into Lua.
		local byte_count = vim.api.nvim_buf_get_offset(bufnr, line_count)

		if byte_count < 0 then
			return { "[Unable to determine buffer size]" }
		end

		if byte_count > MAX_BYTES then
			return { "[Preview disabled: buffer exceeds 256 KiB]" }
		end

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

		if #lines == 0 or (#lines == 1 and lines[1] == "") then
			return { "[empty file]" }
		end

		return lines
	end

	-- Read disk files in binary mode so size checks use actual bytes.
	local file = io.open(path, "rb")

	if not file then
		return { "Unable to preview file" }
	end

	-- One extra byte lets us detect an oversized file without reading
	-- the rest of it. Always close the handle after the read attempt.
	local data, read_error = file:read(MAX_BYTES + 1)
	file:close()

	if read_error then
		return { "Unable to read preview file" }
	end

	data = data or ""

	if #data > MAX_BYTES then
		return { "[Preview disabled: file exceeds 256 KiB]" }
	end

	-- Avoid displaying binary data in the text preview.
	if data:find("\0", 1, true) then
		return { "[Preview disabled: binary file]" }
	end

	if data == "" then
		return { "[empty file]" }
	end

	-- Normalize Windows line endings before splitting into buffer lines.
	data = data:gsub("\r\n", "\n")

	local lines = vim.split(data, "\n", { plain = true })

	-- A final newline terminates the last line rather than adding a row.
	if lines[#lines] == "" then
		table.remove(lines)
	end

	return #lines > 0 and lines or { "" }
end

return M
