local ui = require("picker.ui")

local M = {}

-- Fuzzy matching only keeps the best matches; this keeps typing fast in
-- large trees.
local MAX_RESULTS = 2000

-- List files without blocking; on_done receives vim.system()'s result.
local function list_files(on_done)
  local ok, job = pcall(vim.system, {
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
  }, { text = true }, function(out)
    vim.schedule(function()
      on_done(out)
    end)
  end)

  if not ok then
    vim.notify(
      "Unable to start ripgrep. Check that rg is installed.",
      vim.log.levels.ERROR
    )
    return nil
  end

  return job
end

function M.find_files()
  -- Nil until rg has listed the files.
  local files

  -- The picker's current query and its callback.
  local current

  local function filter(query)
    if query == "" then
      return files
    end

    return vim.fn.matchfuzzy(files, query, { limit = MAX_RESULTS })
  end

  local function publish()
    if files and current then
      current.on_results(filter(current.query))
    end
  end

  local job = list_files(function(out)
    -- --no-messages hides unreadable files, so stderr means a real error.
    if out.code ~= 0 and out.stderr ~= "" then
      vim.notify("rg failed: " .. vim.trim(out.stderr), vim.log.levels.ERROR)
    end

    files = vim.split(out.stdout or "", "\n", { trimempty = true })
    publish()
  end)

  if not job then
    return
  end

  ui.open({
    title = "Find Files",

    search_async = function(query, on_results)
      local search = {
        query = query,
        on_results = on_results,
      }

      current = search
      publish()

      return function()
        if current == search then
          current = nil
        end
      end
    end,

    on_close = function()
      -- The listing may already have finished.
      pcall(job.kill, job, "sigterm")
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
