local ui = require("picker.ui")

local M = {}

local function grep(query)
  if query == "" then
    return {}
  end

  local output = vim.fn.systemlist({
    "rg",
    "--vimgrep",
    "--smart-case",
    "--hidden",
    "--glob",
    "!.git/*",
    "--glob",
    "!node_modules/*",
    "--glob",
    "!dist/*",
    "--glob",
    "!build/*",
    query,
    ".",
  })

  -- ripgrep returns 1 when there are no matches.
  if vim.v.shell_error > 1 then
    return {}
  end

  local results = {}

  for _, line in ipairs(output) do
    local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")

    if file then
      results[#results + 1] = {
        file = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
      }
    end
  end

  return results
end

function M.live_grep()
  ui.open({
    title = "Live Grep",

    search = grep,

    format = function(result)
      return string.format(
        "%s:%d:%d: %s",
        result.file,
        result.lnum,
        result.col,
        result.text
      )
    end,

    preview = function(result)
      return {
        file = result.file,
        lnum = result.lnum,
        col = result.col,
      }
    end,

    select = function(result)
      vim.cmd.edit(vim.fn.fnameescape(result.file))

      local line_count = vim.api.nvim_buf_line_count(0)

      local lnum = math.min(result.lnum, line_count)

      local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""

      local column = math.min(math.max(result.col - 1, 0), #line)

      vim.api.nvim_win_set_cursor(0, { lnum, column })

      vim.cmd("normal! zz")
    end,
  })
end

return M
