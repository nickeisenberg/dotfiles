local ui = require("picker.ui")

local M = {}

local function get_files()
  local files = vim.fn.systemlist({
    "rg",
    "--files",
    "--hidden",
    "--no-messages",
    "--glob",
    "!.git/*",
    "--glob",
    "!node_modules/*",
    "--glob",
    "!.cache/*",
    "--glob",
    "!dist/*",
    "--glob",
    "!build/*",
    "--glob",
    "!*.tmp",
    "--glob",
    "!*.log",
  })

  if vim.v.shell_error ~= 0 then
    return {}
  end

  return files
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
