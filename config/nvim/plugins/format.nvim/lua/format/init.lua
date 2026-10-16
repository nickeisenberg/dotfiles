-- Format buffers with a pipeline of external tools, or the attached LSP.

local apply = require("format.apply")
local config = require("format.config")
local lsp = require("format.lsp")
local pipeline = require("format.pipeline")

local M = {}

-- Special or read-only buffers are never formatted.
local function formattable(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.bo[bufnr].buftype == ""
    and vim.bo[bufnr].modifiable
end

---@param bufnr? integer defaults to the current buffer
function M.format(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not formattable(bufnr) then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  local steps = config.options.formatters[filetype]

  if not steps then
    lsp.format(bufnr)
    return
  end

  -- Give tools a plausible filename for unnamed buffers; ruff and others
  -- use it to choose settings.
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    bufname = "stdin." .. filetype
  end

  local output = pipeline.run(steps, apply.buffer_text(bufnr), bufname)
  if output then
    apply.apply(bufnr, output)
  end
end

---@param opts? table see format.config.defaults
function M.setup(opts)
  config.setup(opts)

  -- Clearing the group makes calling setup() again safe.
  local group = vim.api.nvim_create_augroup("format", { clear = true })

  if config.options.format_on_save then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      desc = "Format before writing",
      callback = function(args)
        M.format(args.buf)
      end,
    })
  end

  vim.api.nvim_create_user_command("Format", function()
    M.format()
  end, { desc = "Format the current buffer" })
end

return M
