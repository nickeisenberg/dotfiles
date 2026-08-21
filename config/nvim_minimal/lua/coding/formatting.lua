local M = {}

-- Filetype -> formatter command
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
    local ft = vim.bo[bufnr].filetype
    local cmd = M.formatters[ft]

    if cmd then
      -- Replace % with the buffer path for formatters that need it.
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local resolved = cmd:gsub("%%", bufname)

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local input = table.concat(lines, "\n")

      local output = vim.fn.system(resolved, input)
      local exit_code = vim.v.shell_error

      if exit_code ~= 0 then
        vim.notify("Formatter failed:\n" .. output, vim.log.levels.ERROR)
        return
      end

      local formatted = vim.split(output, "\n", { plain = true })

      if formatted[#formatted] == "" then
        table.remove(formatted)
      end

      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)

      return
    end

    -- No external formatter configured: fall back to LSP formatting.
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if client:supports_method("textDocument/formatting") then
        vim.lsp.buf.format({
          bufnr = bufnr,
          async = false,
        })
        return
      end
    end
  end,
})

return M
