-- Options.

local M = {}

M.defaults = {
  -- Sign text by kind. The defaults are gitsigns'.
  signs = {
    add = "┃",
    change = "┃",
    delete = "▁", -- lines removed below this one
    topdelete = "▔", -- lines removed above line 1
    changedelete = "~", -- changed, and lines removed below it
  },
  priority = 6, -- sign priority; diagnostics use 10
  base = "index", -- what buffers are compared against: "index" or a revision
  debounce = 100, -- ms between edits and updating the signs
}

M.options = vim.deepcopy(M.defaults)

---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.warn(msg)
  vim.notify("hunks: " .. msg, vim.log.levels.WARN)
end

return M
