local ui = require("picker.ui")

local M = {}

local DEBOUNCE_MS = 100

local debounce_timer
local current_job

local function stop_debounce()
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil
  end
end

local function stop_job()
  if current_job then
    current_job:kill(9)
    current_job = nil
  end
end

local function parse(output)
  local results = {}

  for line in output:gmatch("[^\n]+") do
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

local function run(query, callback)
  current_job = vim.system({
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
  }, { text = true }, function(obj)
    current_job = nil

    -- Killed by a newer search; the caller has already moved on.
    if obj.signal and obj.signal ~= 0 then
      return
    end

    -- ripgrep returns 1 when there are no matches.
    if obj.code > 1 then
      vim.schedule(function()
        callback({})
      end)
      return
    end

    local results = parse(obj.stdout or "")

    vim.schedule(function()
      callback(results)
    end)
  end)
end

local function grep(query, callback)
  stop_debounce()
  stop_job()

  if query == "" then
    callback({})
    return
  end

  debounce_timer = vim.uv.new_timer()

  debounce_timer:start(DEBOUNCE_MS, 0, function()
    stop_debounce()
    run(query, callback)
  end)
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
