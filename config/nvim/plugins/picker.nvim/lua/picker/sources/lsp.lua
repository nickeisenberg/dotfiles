local ui = require("picker.ui")

local M = {}

local function get_line(file, line)
  local bufnr = vim.fn.bufnr(file)

  -- If the file is currently loaded, read from the live buffer.
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    local lines = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)

    if lines[1] then
      return lines[1]
    end
  end

  -- Otherwise read from disk.
  local ok, lines = pcall(vim.fn.readfile, file, "", line)

  if ok and lines[line] then
    return lines[line]
  end

  return ""
end

local function location_to_item(location, encoding)
  local uri = location.uri or location.targetUri
  local range = location.range or location.targetSelectionRange

  if not uri or not range then
    return nil
  end

  local file = vim.uri_to_fname(uri)
  local line = range.start.line + 1
  local raw = get_line(file, line)
  -- The server counts columns in its offset encoding (often UTF-16);
  -- Neovim counts bytes.
  local col = vim.str_byteindex(raw, encoding, range.start.character, false) + 1
  local text = vim.trim(raw)

  return {
    display = string.format(
      "%s:%d:%d: %s",
      vim.fn.fnamemodify(file, ":."),
      line,
      col,
      text
    ),
    file = file,
    line = line,
    col = col,
    text = text,
  }
end

local function open_locations(title, items)
  table.sort(items, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end

    if a.line ~= b.line then
      return a.line < b.line
    end

    return a.col < b.col
  end)

  ui.open({
    title = title,

    initial_results = items,

    search = function(query)
      if query == "" then
        return items
      end

      local displays = {}

      for _, item in ipairs(items) do
        displays[#displays + 1] = item.display
      end

      local matches = vim.fn.matchfuzzy(displays, query)

      local by_display = {}

      for _, item in ipairs(items) do
        by_display[item.display] = item
      end

      local filtered = {}

      for _, display in ipairs(matches) do
        local item = by_display[display]

        if item then
          filtered[#filtered + 1] = item
        end
      end

      return filtered
    end,

    format = function(item)
      return item.display
    end,

    preview = function(item)
      return {
        file = item.file,
        lnum = item.line,
        col = item.col,
      }
    end,

    select = function(item)
      vim.cmd.edit(vim.fn.fnameescape(item.file))

      -- The file may have changed since the server answered.
      local lnum = math.min(item.line, vim.api.nvim_buf_line_count(0))
      local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""

      vim.api.nvim_win_set_cursor(0, {
        lnum,
        math.min(item.col - 1, #line),
      })

      vim.cmd("normal! zz")
    end,
  })
end

function M.references()
  local bufnr = vim.api.nvim_get_current_buf()

  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/references",
  })

  if #clients == 0 then
    vim.notify("No LSP client supports references", vim.log.levels.WARN)
    return
  end

  local client = clients[1]

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  params.context = {
    includeDeclaration = true,
  }

  -- Only the client whose offset encoding built `params`; buf_request()
  -- would ask every attached server and open a picker for each answer.
  client:request("textDocument/references", params, function(err, result)
    if err then
      vim.notify(
        "LSP references failed: " .. (err.message or tostring(err)),
        vim.log.levels.ERROR
      )
      return
    end

    if not result or vim.tbl_isempty(result) then
      vim.notify("No references found")
      return
    end

    local items = {}

    for _, location in ipairs(result) do
      local item = location_to_item(location, client.offset_encoding)

      if item then
        items[#items + 1] = item
      end
    end

    if #items == 0 then
      vim.notify("No references found")
      return
    end

    open_locations("References", items)
  end, bufnr)
end

function M.definitions()
  local bufnr = vim.api.nvim_get_current_buf()

  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/definition",
  })

  if #clients == 0 then
    vim.notify("No LSP client supports definitions", vim.log.levels.WARN)
    return
  end

  local client = clients[1]

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  -- Only the client whose offset encoding built `params`; buf_request()
  -- would ask every attached server and open a picker for each answer.
  client:request("textDocument/definition", params, function(err, result)
    if err then
      vim.notify(
        "LSP definition failed: " .. (err.message or tostring(err)),
        vim.log.levels.ERROR
      )
      return
    end

    if not result or vim.tbl_isempty(result) then
      vim.notify("No definitions found")
      return
    end

    -- Definition may return a single Location/LocationLink
    -- instead of a list.
    if result.uri or result.targetUri then
      result = { result }
    end

    local items = {}

    for _, location in ipairs(result) do
      local item = location_to_item(location, client.offset_encoding)

      if item then
        items[#items + 1] = item
      end
    end

    if #items == 0 then
      vim.notify("No definitions found")
      return
    end

    open_locations("Definitions", items)
  end, bufnr)
end

return M
