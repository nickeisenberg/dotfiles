-- Writing formatted text back into a buffer.
--
-- Only the lines that changed are replaced. Replacing the whole buffer
-- would also work, but it drops marks, folds, extmarks (diagnostics, git
-- signs) and the cursor's place on lines the formatter never touched.

local M = {}

local function buffer_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n") .. "\n"
end

M.buffer_text = buffer_text

-- Replace the buffer's contents with `text` by applying a line diff.
---@param bufnr integer
---@param text string
function M.apply(bufnr, text)
  -- Buffers hold lines without a final newline; diff both sides the same
  -- way so a missing trailing newline isn't seen as a change.
  if text:sub(-1) ~= "\n" then
    text = text .. "\n"
  end

  local old = buffer_text(bufnr)
  if old == text then
    return
  end

  local new_lines = vim.split(text, "\n", { plain = true })
  table.remove(new_lines) -- the empty string after the final newline

  local hunks = vim.text.diff(old, text, { result_type = "indices" })
  ---@cast hunks integer[][]

  -- Apply from the bottom up so earlier hunks' line numbers stay valid.
  for i = #hunks, 1, -1 do
    local start_a, count_a, start_b, count_b = unpack(hunks[i])
    local replacement =
      vim.list_slice(new_lines, start_b, start_b + count_b - 1)

    -- A pure insertion (count_a == 0) goes after line start_a.
    local first = count_a == 0 and start_a or start_a - 1
    vim.api.nvim_buf_set_lines(
      bufnr,
      first,
      first + count_a,
      false,
      replacement
    )
  end
end

return M
