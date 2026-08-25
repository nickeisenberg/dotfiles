-- lua/config/format.lua
--
-- Format on save:
--   Lua:    StyLua
--   JSON:   Prettier
--   Python: Ruff fixes/import organization, then Ruff formatting
--   Other:  attached LSP formatter, when available

local M = {}

-- A formatter is a list of commands run in order.
-- Each command receives the previous command's output through stdin.
M.formatters = {
  lua = {
    {
      command = "stylua",
      args = { "-" },
    },
  },
  json = {
    {
      command = "prettier",
      args = function(bufname)
        return {
          -- Lets Prettier infer parsing and configuration from the filename.
          "--stdin-filepath",
          bufname,
        }
      end,
    },
  },

  python = {
    {
      command = "ruff",
      args = function(bufname)
        return {
          "check",
          "--fix",
          "--exit-zero",
          "--stdin-filename",
          bufname,
          "-",
        }
      end,
    },
    {
      command = "ruff",
      args = function(bufname)
        return {
          "format",
          "--stdin-filename",
          bufname,
          "-",
        }
      end,
    },
  },
}

-- Resolve either a static argument table or a function that generates
-- arguments from the current buffer's filename.
local function get_args(step, bufname)
  if type(step.args) == "function" then
    return step.args(bufname)
  end

  return step.args or {}
end

-- Convert buffer lines to newline-terminated text for stdin-based tools.
local function get_buffer_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, "\n") .. "\n"

  return lines, text
end

-- Replace the entire buffer only when formatter output differs.
local function set_formatted_buffer(bufnr, original_lines, output)
  local formatted_lines = vim.split(output, "\n", {
    plain = true,
  })

  -- Neovim buffers hold lines without trailing newline characters.
  if formatted_lines[#formatted_lines] == "" then
    table.remove(formatted_lines)
  end

  -- Avoid unnecessary buffer changes and undo entries.
  if vim.deep_equal(original_lines, formatted_lines) then
    return true
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted_lines)
  return true
end

-- Run an external formatter pipeline synchronously.
local function format_external(bufnr, pipeline)
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  -- Give stdin-based formatters a plausible filename for unnamed buffers.
  if bufname == "" then
    bufname = "stdin." .. vim.bo[bufnr].filetype
  end

  local original_lines, input = get_buffer_text(bufnr)

  for _, step in ipairs(pipeline) do
    if vim.fn.executable(step.command) ~= 1 then
      vim.notify("Formatter not found: " .. step.command, vim.log.levels.WARN)
      return false
    end

    local command = {
      step.command,
      unpack(get_args(step, bufname)),
    }

    local result = vim
      .system(command, {
        stdin = input,
        text = true,
      })
      :wait()

    if result.code ~= 0 then
      local message = result.stderr

      if not message or message == "" then
        message = step.command .. " failed while formatting"
      end

      vim.notify(message, vim.log.levels.WARN)
      return false
    end

    -- Pass the transformed text into the next pipeline command.
    -- Ruff and stdin-based formatters normally return formatted source here.
    if result.stdout and result.stdout ~= "" then
      input = result.stdout
    end
  end

  return set_formatted_buffer(bufnr, original_lines, input)
end

-- Fall back to an attached LSP formatter when no external pipeline exists.
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

  -- Do not format invalid, special, or non-editable buffers.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.bo[bufnr].buftype ~= "" then
    return
  end

  if not vim.bo[bufnr].modifiable then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  local pipeline = M.formatters[filetype]

  if pipeline then
    format_external(bufnr, pipeline)
    return
  end

  format_lsp(bufnr)
end

-- Clear the augroup so reloading this module does not duplicate autocmds.
local format_group = vim.api.nvim_create_augroup("FormatOnSave", {
  clear = true,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = format_group,
  callback = function(args)
    M.format(args.buf)
  end,
})

return M
