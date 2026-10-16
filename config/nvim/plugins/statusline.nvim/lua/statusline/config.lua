-- Options.

local M = {}

M.defaults = {
  -- Parts of the active window's statusline; each can be turned off.
  -- Inactive windows show only the path and its [+]/[RO] flags.
  show = {
    mode = true,
    git = true, -- branch
    diff = true, -- +added ~changed -removed, from gitsigns when loaded
    diagnostics = true,
    lsp = true, -- progress while a server works, else attached servers
    filetype = true,
    position = true, -- line:column
  },
  -- Diagnostic labels by severity. The defaults are Nerd Font codicons.
  icons = {
    error = "\u{EA87} ",
    warn = "\u{EA6C} ",
    info = "\u{EA74} ",
    hint = "\u{EA61} ",
  },
}

M.options = vim.deepcopy(M.defaults)

---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

return M
