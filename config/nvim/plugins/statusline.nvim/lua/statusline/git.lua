-- The repository a buffer belongs to, its current branch, and the lines
-- changed since the file was staged.
--
-- The branch is read straight from the repository's HEAD file instead of
-- running git: one small read, redone only when HEAD changes, so the
-- statusline follows a checkout made anywhere (a shell, another plugin)
-- with no process and no event to wait for.
--
-- Changed lines come from diffing the buffer against the staged copy of
-- the file. That copy is read with `git show` only when the index file
-- changes, so staging from anywhere is picked up the same way.

local M = {}

-- buffer name -> repository root, or false outside a repository.
local roots = {}

-- HEAD path -> { mtime = integer, branch = string }.
local heads = {}

-- buffer number -> { path, index = index mtime, base = staged text (false
-- when the file isn't tracked, nil while it's read), tick, counts }.
local diffs = {}

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.mtime.nsec + stat.mtime.sec * 1e9
end

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
  local time = mtime(head)
  if not time then
    return nil
  end

  local hit = heads[head]
  if hit and hit.mtime == time then
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
  heads[head] = { mtime = time, branch = branch }
  return branch
end

-- Count the hunks: lines replaced one for one are changed, the rest
-- added or removed.
local function count(base, text)
  local counts = { added = 0, changed = 0, removed = 0 }
  for _, h in ipairs(vim.text.diff(base, text, { result_type = "indices" })) do
    local old, new = h[2], h[4]
    local changed = math.min(old, new)
    counts.changed = counts.changed + changed
    counts.added = counts.added + new - changed
    counts.removed = counts.removed + old - changed
  end
  return counts
end

-- Reading the staged copy runs git in the background; the statusline is
-- redrawn once it arrives.
local function read_base(d, root, path)
  local ok = pcall(vim.system, {
    "git",
    "-C",
    root,
    "show",
    ":" .. path:sub(#root + 2),
  }, { text = true }, function(res)
    d.base = res.code == 0 and res.stdout or false
    vim.schedule(function()
      vim.cmd.redrawstatus({ bang = true })
    end)
  end)
  if not ok then
    d.base = false -- git isn't installed
  end
end

---@param bufnr integer
---@param root string
---@param path string the buffer's absolute path
---@return { added: integer, changed: integer, removed: integer }?
function M.diff(bufnr, root, path)
  local index = mtime(git_dir(root) .. "/index")
  local d = diffs[bufnr]
  if not d or d.path ~= path or d.index ~= index then
    d = { path = path, index = index }
    diffs[bufnr] = d
    read_base(d, root, path)
  end
  if not d.base then
    return nil
  end

  local tick = vim.b[bufnr].changedtick
  if d.tick ~= tick then
    -- `git show` text has LF endings (vim.system's text mode drops CRs);
    -- end the buffer's text the way the file was read.
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local eol = vim.bo[bufnr].eol and "\n" or ""
    d.counts = count(d.base, table.concat(lines, "\n") .. eol)
    d.tick = tick
  end
  return d.counts
end

---@param ev table the BufWipeout autocmd event
function M.on_wipeout(ev)
  diffs[ev.buf] = nil
end

return M
