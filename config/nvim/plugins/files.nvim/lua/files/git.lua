-- Git status of a directory buffer's entries, as the two letters of `git
-- status --short` in the sign column: staged, then unstaged. A directory
-- shows the first status found inside it.

local config = require("files.config")
local view = require("files.view")

local M = {}

local ns = vim.api.nvim_create_namespace("files_git")

-- Unstaged changes win over staged ones, so work still to stage stands
-- out.
local function highlight(xy)
  if xy == "??" then
    return "FilesGitUntracked"
  elseif xy:find("U") or xy == "AA" or xy == "DD" then
    return "FilesGitConflict"
  end
  return xy:sub(2, 2) ~= " " and "FilesGitUnstaged" or "FilesGitStaged"
end

-- child name -> "XY", from `git status --porcelain -z` output, for the
-- entries of `dir` in the repository at `root`.
local function parse(output, root, dir)
  local status = {}
  local records = vim.split(output, "\0", { plain = true })
  local i = 1
  while i <= #records do
    local record = records[i]
    if #record > 3 then
      local xy, path = record:sub(1, 2), record:sub(4)
      -- A rename or copy is followed by the old path.
      if xy:find("[RC]") then
        i = i + 1
      end
      local full = root .. "/" .. path
      if vim.startswith(full, dir .. "/") then
        local child = full:sub(#dir + 2):match("^[^/]+")
        status[child] = status[child] or xy
      end
    end
    i = i + 1
  end
  return status
end

local function place(bufnr, status)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local entry = view.parse(line)
    local xy = entry and status[entry.name]
    if xy then
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        sign_text = xy,
        sign_hl_group = highlight(xy),
      })
    end
  end
end

-- Fetch the status in the background and place the signs.
function M.update(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not config.options.git then
    return
  end
  local dir = vim.uv.fs_realpath(view.dir(bufnr) or "")
  local root = dir and vim.fs.root(dir, ".git")
  if not root then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    return
  end
  local tick = vim.b[bufnr].changedtick
  pcall(
    vim.system,
    {
      "git",
      "-C",
      root,
      "--no-pager",
      "status",
      "--porcelain",
      "-z",
      "--untracked-files=normal",
      "--",
      dir,
    },
    {},
    vim.schedule_wrap(function(res)
      -- Drop it if the buffer was re-read since.
      if
        res.code == 0
        and vim.api.nvim_buf_is_loaded(bufnr)
        and vim.b[bufnr].changedtick == tick
      then
        place(bufnr, parse(res.stdout, root, dir))
      end
    end)
  )
end

return M
