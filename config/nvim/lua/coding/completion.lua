-- A small native Neovim path-completion source.
-- It does not use nvim-cmp or any completion plugin.

local uv = vim.uv or vim.loop

local group = vim.api.nvim_create_augroup("native_completion", {
  clear = true,
})

-- Find the path-like token directly before the cursor.
-- Quotes, whitespace, and common brackets terminate a path.
local function path_token_before_cursor(line_before_cursor)
  return line_before_cursor:match([[([^%s"'`%(%)%[%]{}<>]+)$]])
end

-- Show filesystem candidates in Neovim's native completion menu.
--
-- Returns true when the text before the cursor is a path and this function
-- handled completion. Returns false when the text is not path-like, allowing
-- the caller to fall back to LSP completion.
local function complete_path()
  -- Do not overwrite an LSP or existing native completion popup.
  if vim.fn.pumvisible() == 1 then
    return false
  end

  local line = vim.api.nvim_get_current_line()

  -- nvim_win_get_cursor() gives a zero-based byte column.
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, cursor_col)

  local typed_path = path_token_before_cursor(before_cursor)
  if not typed_path then
    return false
  end

  -- Split a token such as `~/projects/nv` into:
  --   directory: `~/projects/`
  --   prefix:    `nv`
  --
  -- Requiring a slash prevents normal words from causing filesystem scans.
  local typed_directory, prefix = typed_path:match("^(.*[/])([^/]*)$")
  if not typed_directory then
    return false
  end

  -- Expand `~` only for scanning. We preserve the originally typed form
  -- in the completion item, so `~/foo` stays `~/foo` when inserted.
  local scan_directory = vim.fn.expand(typed_directory)

  local ok, directory_handle = pcall(uv.fs_scandir, scan_directory)
  if not ok or not directory_handle then
    -- It was path-shaped, but points at a nonexistent/unreadable directory.
    -- Treat it as handled so LSP completion does not replace the path token.
    return true
  end

  local matches = {}

  while true do
    local name, entry_type = uv.fs_scandir_next(directory_handle)

    if not name then
      break
    end

    -- Simple prefix matching, like ordinary filesystem completion.
    if name:sub(1, #prefix) == prefix then
      local is_directory = entry_type == "directory"

      -- `word` is the complete replacement text starting at `start_col`.
      local candidate = typed_directory .. name

      matches[#matches + 1] = {
        word = candidate,
        abbr = name .. (is_directory and "/" or ""),
        menu = is_directory and "[dir]" or "[file]",
        kind = is_directory and "Folder" or "File",
      }
    end
  end

  if #matches == 0 then
    return true
  end

  table.sort(matches, function(left, right)
    -- Show directories before files, then sort alphabetically.
    local left_is_dir = left.kind == "Folder"
    local right_is_dir = right.kind == "Folder"

    if left_is_dir ~= right_is_dir then
      return left_is_dir
    end

    return left.word < right.word
  end)

  -- `complete()` uses a one-based byte column.
  -- Replace the entire path token, not only its final component.
  local start_col = cursor_col - #typed_path + 1

  vim.fn.complete(start_col, matches)
  return true
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if not client then
      return
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, {
        autotrigger = true,
      })
    end
  end,
})

vim.api.nvim_create_autocmd("TextChangedI", {
  group = group,
  callback = function()
    if complete_path() then
      return
    end

    if vim.fn.pumvisible() == 1 then
      return
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)

    if before:match("[%w_][%w_]$") then
      vim.lsp.completion.get()
    end
  end,
})

vim.api.nvim_create_autocmd("InsertCharPre", {
  group = group,
  callback = function()
    if vim.v.char == "(" or vim.v.char == "," then
      vim.schedule(function()
        -- Check if any attached client supports signature help
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })

        local has_signature_help = false
        for _, client in ipairs(clients) do
          if client.server_capabilities.signatureHelpProvider then
            has_signature_help = true
            break
          end
        end

        if has_signature_help then
          vim.lsp.buf.signature_help({
            border = "rounded",
          })
        end
      end)
    end
  end,
})

vim.opt.completeopt = {
  "menu",
  "menuone",
  "noselect",
}
