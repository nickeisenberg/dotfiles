local M = {}

M.formatters = {
  lua = {
    command = "stylua",
    args = { "-" },
  },

  json = {
    command = "prettier",
    args = function(bufname)
      return {
        "--stdin-filepath",
        bufname,
      }
    end,
  },

  python = {
    command = "ruff",
    args = {
      "format",
      "-",
    },
  },
}

local function get_args(formatter, bufname)
  if type(formatter.args) == "function" then
    return formatter.args(bufname)
  end

  return formatter.args or {}
end

local function format_external(bufnr, formatter)
  if vim.fn.executable(formatter.command) ~= 1 then
    vim.notify(
      "Formatter not found: " .. formatter.command,
      vim.log.levels.WARN
    )
    return false
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr)

  local command = {
    formatter.command,
    unpack(get_args(formatter, bufname)),
  }

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Preserve the final newline expected by stdin formatters.
  local input = table.concat(lines, "\n") .. "\n"

  local result = vim
    .system(command, {
      stdin = input,
      text = true,
    })
    :wait()

  if result.code ~= 0 then
    vim.schedule(function()
      vim.notify(
        formatter.command .. ": formatting skipped",
        vim.log.levels.WARN
      )
    end)

    return false
  end

  if not result.stdout then
    return false
  end

  local formatted = vim.split(result.stdout, "\n", {
    plain = true,
  })

  -- stdout normally ends in a newline.
  if formatted[#formatted] == "" then
    table.remove(formatted)
  end

  -- Don't touch the buffer if the formatter made no changes.
  if vim.deep_equal(lines, formatted) then
    return true
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)

  return true
end

local function format_lsp(bufnr)
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
  })

  return true
end

function M.format(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.bo[bufnr].buftype ~= "" then
    return
  end

  local ft = vim.bo[bufnr].filetype
  local formatter = M.formatters[ft]

  if formatter then
    format_external(bufnr, formatter)
    return
  end

  format_lsp(bufnr)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    M.format(args.buf)
  end,
})

return M
