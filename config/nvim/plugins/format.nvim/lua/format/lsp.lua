-- Falling back to an attached language server's formatter.

local config = require("format.config")

local M = {}

-- Format with an LSP client. Returns false when no attached client can.
---@param bufnr integer
---@return boolean
function M.format(bufnr)
  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/formatting",
  })

  if #clients == 0 then
    return false
  end

  vim.lsp.buf.format({
    bufnr = bufnr,
    async = false,
    timeout_ms = config.options.timeout_ms,
  })
  return true
end

return M
