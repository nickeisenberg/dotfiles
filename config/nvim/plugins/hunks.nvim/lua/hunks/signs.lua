-- Hunks as signs, placed as extmarks.

local config = require("hunks.config")

local M = {}

local ns = vim.api.nvim_create_namespace("hunks")

local groups = {
  add = "HunksAdd",
  change = "HunksChange",
  delete = "HunksDelete",
  topdelete = "HunksTopDelete",
  changedelete = "HunksChangeDelete",
}

-- Run again on ColorScheme, which clears them.
function M.highlights()
  local function link(name, to)
    vim.api.nvim_set_hl(0, name, { link = to, default = true })
  end
  link("HunksAdd", "Added")
  link("HunksChange", "Changed")
  link("HunksDelete", "Removed")
  link("HunksTopDelete", "HunksDelete")
  link("HunksChangeDelete", "HunksChange")
end

-- line (1-based) -> kind, for a list of hunks.
function M.for_hunks(hunks)
  local signs = {}
  for _, h in ipairs(hunks) do
    if h.old_count == 0 then
      for i = 1, h.new_count do
        signs[h.new_start + i] = "add"
      end
    elseif h.new_count == 0 then
      if h.new_start == 0 then
        signs[1] = "topdelete"
      else
        signs[h.new_start] = "delete"
      end
    else
      for i = 1, h.new_count do
        signs[h.new_start + i] = i <= h.old_count and "change" or "add"
      end
      if h.old_count > h.new_count then
        signs[h.new_start + h.new_count] = "changedelete"
      end
    end
  end
  return signs
end

function M.place(bufnr, hunks)
  M.clear(bufnr)
  local opts = config.options
  local count = vim.api.nvim_buf_line_count(bufnr)
  for lnum, kind in pairs(M.for_hunks(hunks)) do
    if lnum <= count then
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, 0, {
        sign_text = opts.signs[kind],
        sign_hl_group = groups[kind],
        priority = opts.priority,
      })
    end
  end
end

function M.clear(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
end

return M
