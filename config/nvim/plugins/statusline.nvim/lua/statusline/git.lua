-- The repository a buffer belongs to, and its current branch.
--
-- The branch is read straight from the repository's HEAD file instead of
-- running git: one small read, redone only when HEAD changes, so the
-- statusline follows a checkout made anywhere (a shell, fugitive) with no
-- process and no event to wait for.

local M = {}

-- buffer name -> repository root, or false outside a repository.
local roots = {}

-- HEAD path -> { mtime = integer, branch = string }.
local heads = {}

---@param path string a file's absolute path
---@return string? root
function M.root(path)
  if roots[path] == nil then
    -- vim.fs.root also finds worktrees and submodules, whose .git is a
    -- file rather than a directory.
    roots[path] = vim.fs.root(path, ".git") or false
  end
  return roots[path] or nil
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

---@param root string
---@return string? branch the branch name, or a short hash when detached
function M.branch(root)
  local head = git_dir(root) .. "/HEAD"
  local stat = vim.uv.fs_stat(head)
  if not stat then
    return nil
  end

  local hit = heads[head]
  if hit and hit.mtime == stat.mtime.nsec + stat.mtime.sec * 1e9 then
    return hit.branch
  end

  local file = io.open(head, "r")
  local line = file and file:read("*l") or ""
  if file then
    file:close()
  end

  local branch = line:match("^ref: refs/heads/(.+)$")
    or line:match("^ref: (.+)$")
    or line:sub(1, 7)
  if branch == "" then
    branch = nil
  end
  heads[head] = {
    mtime = stat.mtime.nsec + stat.mtime.sec * 1e9,
    branch = branch,
  }
  return branch
end

return M
