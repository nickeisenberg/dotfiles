-- Running git: the repository a file is in, when its index or HEAD last
-- changed, and the file's text at the base.

local M = {}

-- file path -> repository root, or false outside a repository.
local roots = {}

---@param path string
---@return string?
function M.root(path)
  if roots[path] == nil then
    -- Finds worktrees and submodules too, whose .git is a file.
    roots[path] = vim.fs.root(path, ".git") or false
  end
  return roots[path] or nil
end

-- A `git init` from a shell can put a path in a repository.
function M.forget_roots()
  roots = {}
end

-- The git directory for a root: .git itself, or where a .git file
-- ("gitdir: <path>") points.
local function git_dir(root)
  local dot_git = root .. "/.git"
  local stat = vim.uv.fs_stat(dot_git)
  if not stat or stat.type == "directory" then
    return dot_git
  end

  local file = io.open(dot_git, "r")
  local line = file and file:read("*l") or ""
  if file then
    file:close()
  end
  local dir = line:match("^gitdir:%s*(.-)%s*$")
  if not dir then
    return dot_git
  end
  if dir:sub(1, 1) ~= "/" then
    dir = root .. "/" .. dir
  end
  return vim.fs.normalize(dir)
end

-- Changes when the base may have: the index is rewritten by add, commit,
-- checkout and reset; HEAD and logs/HEAD by anything that moves HEAD.
---@param root string
---@return string
function M.stamp(root)
  local dir = git_dir(root)
  local parts = {}
  for _, name in ipairs({ "index", "HEAD", "logs/HEAD" }) do
    local stat = vim.uv.fs_stat(dir .. "/" .. name)
    parts[#parts + 1] = stat
        and ("%d.%d:%d"):format(stat.mtime.sec, stat.mtime.nsec, stat.size)
      or "-"
  end
  return table.concat(parts, " ")
end

local function command(root, args)
  return vim.list_extend({ "git", "-C", root, "--no-pager" }, args)
end

-- Read `relpath` at `base` ("index" or a revision) in the background, then
-- call `on_done(text)` on the main loop; text is nil when git fails, e.g.
-- for an untracked file.
function M.show(root, relpath, base, on_done)
  -- The ./ makes the path relative to the root.
  local object = (base == "index" and "" or base) .. ":./" .. relpath
  local ok = pcall(
    vim.system,
    command(root, { "show", object }),
    {},
    vim.schedule_wrap(function(res)
      on_done(res.code == 0 and res.stdout or nil)
    end)
  )
  if not ok then
    vim.schedule(function()
      on_done(nil) -- git isn't installed
    end)
  end
end

-- Run git and wait for it, for commands you run by hand. Returns stdout,
-- or nil and the error.
---@param input? string written to stdin
---@return string?, string?
function M.run(root, args, input)
  local ok, job =
    pcall(vim.system, command(root, args), { stdin = input or false })
  if not ok then
    return nil, "git could not be started"
  end
  local res = job:wait(10000)
  if res.code ~= 0 then
    local err = vim.trim(res.stderr or "")
    return nil, err ~= "" and err or ("git exited with %d"):format(res.code)
  end
  return res.stdout
end

return M
