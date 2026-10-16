local M = {}

local SIDE_PREVIEW_MIN_COLUMNS = 120
local BOTTOM_PREVIEW_MIN_LINES = 35

function M.get()
	if vim.o.columns >= SIDE_PREVIEW_MIN_COLUMNS then
		return "side"
	end

	if vim.o.lines >= BOTTOM_PREVIEW_MIN_LINES then
		return "bottom"
	end

	return "none"
end

return M
