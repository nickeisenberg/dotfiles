local ui = require("picker.ui")

local M = {}

local function get_buffers()
  local results = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
      local name = vim.api.nvim_buf_get_name(bufnr)

      if name ~= "" then
        results[#results + 1] = {
          bufnr = bufnr,
          path = name,
          display = vim.fn.fnamemodify(name, ":."),
        }
      end
    end
  end

  return results
end

function M.find_buffers()
  local buffers = get_buffers()

  ui.open({
    title = "Find Buffers",

    initial_results = buffers,

    search = function(query)
      if query == "" then
        return buffers
      end

      local names = {}

      for _, buffer in ipairs(buffers) do
        names[#names + 1] = buffer.display
      end

      local matches = vim.fn.matchfuzzypos(names, query)
      local matched_names = matches[1]

      local by_name = {}

      for _, buffer in ipairs(buffers) do
        by_name[buffer.display] = buffer
      end

      local results = {}

      for _, name in ipairs(matched_names) do
        local buffer = by_name[name]

        if buffer then
          results[#results + 1] = buffer
        end
      end

      return results
    end,

    format = function(buffer)
      return buffer.display
    end,

    preview = function(buffer)
      return {
        file = buffer.path,
      }
    end,

    select = function(buffer)
      if vim.api.nvim_buf_is_valid(buffer.bufnr) then
        vim.api.nvim_set_current_buf(buffer.bufnr)
      end
    end,
  })
end

return M
