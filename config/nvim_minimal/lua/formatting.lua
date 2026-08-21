local M = {}

-- User-configurable: filetype -> shell command (stdin/stdout)
M.formatters = {
  lua = "stylua -",
  javascript = "prettier --stdin-filepath %",
  typescript = "prettier --stdin-filepath %",
  typescriptreact = "prettier --stdin-filepath %",
  json = "prettier --stdin-filepath %",
}

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    local bufnr = args.buf

    -- local ft = vim.bo[bufnr].filetype
    -- vim.notify("FORMAT CALLBACK: filetype=" .. ft)

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local input = table.concat(lines, "\n")

    local output = vim.fn.system("stylua -", input)
    local exit_code = vim.v.shell_error

    vim.notify("stylua exit code: " .. exit_code)

    if exit_code ~= 0 then
      vim.notify("stylua failed:\n" .. output, vim.log.levels.ERROR)
      return
    end

    local formatted = vim.split(output, "\n", { plain = true })

    if formatted[#formatted] == "" then
      table.remove(formatted)
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
  end,
})

return M
