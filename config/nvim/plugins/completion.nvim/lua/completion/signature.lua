-- Opening signature help when you type a character that starts or moves
-- through an argument list.

local config = require("completion.config")

local M = {}

-- The characters that open signature help in a buffer: the configured
-- list, or else what the attached servers ask for.
local function triggers(bufnr)
  local fixed = config.options.signature.triggers
  if fixed then
    return fixed
  end

  local chars = {}
  for _, client in
    ipairs(vim.lsp.get_clients({
      bufnr = bufnr,
      method = "textDocument/signatureHelp",
    }))
  do
    local provider = client.server_capabilities.signatureHelpProvider or {}
    vim.list_extend(chars, provider.triggerCharacters or {})
    vim.list_extend(chars, provider.retriggerCharacters or {})
  end
  return chars
end

local function on_char()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.list_contains(triggers(bufnr), vim.v.char) then
    return
  end

  -- The typed character isn't in the buffer yet; ask once it is.
  vim.schedule(function()
    vim.lsp.buf.signature_help({
      border = config.options.signature.border,
      focusable = false,
      silent = true,
    })
  end)
end

---@param group integer
function M.setup(group)
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = group,
    desc = "Open signature help on trigger characters",
    callback = on_char,
  })
end

return M
