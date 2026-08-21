local ui = require("picker.ui")

local M = {}

local function location_to_item(location, client)
  local uri = location.uri or location.targetUri
  local range = location.range or location.targetSelectionRange

  if not uri or not range then
    return nil
  end

  local file = vim.uri_to_fname(uri)

  local line = range.start.line + 1
  local col = range.start.character + 1

  local text = ""

  local ok, lines = pcall(vim.fn.readfile, file, "", line)

  if ok and lines[line] then
    text = vim.trim(lines[line])
  end

  local display = string.format("%s:%d:%d: %s", vim.fn.fnamemodify(file, ":."), line, col, text)

  return {
    display = display,
    file = file,
    line = line,
    col = col,
    text = text,
    client = client,
  }
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

  local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)

  params.context = {
    includeDeclaration = true,
  }

  vim.lsp.buf_request_all(bufnr, "textDocument/references", params, function(results)
    local items = {}

    for client_id, response in pairs(results) do
      if response.result then
        local client = vim.lsp.get_client_by_id(client_id)

        for _, location in ipairs(response.result) do
          local item = location_to_item(location, client)

          if item then
            items[#items + 1] = item
          end
        end
      end
    end

    if #items == 0 then
      vim.notify("No references found")
      return
    end

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
      title = "References",

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

        vim.api.nvim_win_set_cursor(0, {
          item.line,
          item.col - 1,
        })

        vim.cmd("normal! zz")
      end,
    })
  end)
end

return M
