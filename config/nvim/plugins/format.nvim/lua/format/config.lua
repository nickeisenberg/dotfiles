-- Options, and the notify helper every module shares.

local M = {}

M.defaults = {
  -- filetype -> pipeline. A pipeline is a list of steps run in order, each
  -- reading the previous step's output on stdin:
  --   { command = "stylua", args = { "-" } }
  -- `args` can also be a function(bufname) returning the list.
  -- Filetypes without a pipeline fall back to an attached LSP formatter.
  formatters = {},
  -- Format every buffer before it is written.
  format_on_save = true,
  -- How long one step (or the LSP request) may take before it is given up.
  timeout_ms = 5000,
}

M.options = vim.deepcopy(M.defaults)

---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.notify(msg, level)
  vim.notify("format: " .. msg, level or vim.log.levels.INFO)
end

return M
