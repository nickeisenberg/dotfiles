local ui = require("picker.ui")

local M = {}

local ignore_patterns = {
  "node_modules",
  "%.git",
  "%.cache",
  "dist",
  "build",
  "%.tmp",
  "%.log",
}

local function should_ignore(path)
  for _, pattern in ipairs(ignore_patterns) do
    if path:match(pattern) then
      return true
    end
  end

  return false
end

local function get_files()
  local files = vim.fn.glob("**/*", true, true)
  local result = {}

  for _, file in ipairs(files) do
    if vim.fn.isdirectory(file) == 0 and not should_ignore(file) then
      result[#result + 1] = file
    end
  end

  return result
end

function M.find_files()
  local files = get_files()

  ui.open({
    title = "Find Files",

    initial_results = files,

    search = function(query)
      if query == "" then
        return files
      end

      return vim.fn.matchfuzzy(files, query)
    end,

    format = function(file)
      return file
    end,

    preview = function(file)
      return {
        file = file,
      }
    end,

    select = function(file)
      vim.cmd.edit(vim.fn.fnameescape(file))
    end,
  })
end

return M
