-- Reading directories and changing the file system. Every change refuses
-- to overwrite an existing path, and returns true, or false and why.

local config = require("files.config")

local M = {}

local uv = vim.uv

---@return boolean
function M.exists(path)
  return uv.fs_lstat(path) ~= nil
end

---@return boolean
function M.is_dir(path)
  return vim.fn.isdirectory(path) == 1
end

local function make_parent(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
end

-- The entries of `dir`: { name, dir }, directories first, then by name.
-- A link to a directory counts as one. nil and why when unreadable.
---@return { name: string, dir: boolean }[]?, string?
function M.read_dir(dir)
  local handle, err = uv.fs_scandir(dir)
  if not handle then
    return nil, err
  end
  local entries = {}
  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if config.options.show_hidden or name:sub(1, 1) ~= "." then
      local dir_like = type == "directory"
        or (type == "link" and M.is_dir(dir .. "/" .. name))
      entries[#entries + 1] = { name = name, dir = dir_like }
    end
  end
  table.sort(entries, function(a, b)
    if a.dir ~= b.dir then
      return a.dir
    end
    return a.name:lower() < b.name:lower()
  end)
  return entries
end

function M.create(path, dir)
  if M.exists(path) then
    return false, "already exists"
  end
  if dir then
    return vim.fn.mkdir(path, "p") == 1, "mkdir failed"
  end
  make_parent(path)
  local fd, err = uv.fs_open(path, "wx", tonumber("644", 8))
  if not fd then
    return false, err
  end
  uv.fs_close(fd)
  return true
end

function M.copy(from, to)
  if M.exists(to) then
    return false, "already exists"
  end
  local stat = uv.fs_lstat(from)
  if not stat then
    return false, "no longer exists"
  end
  make_parent(to)
  if stat.type == "link" then
    local target, err = uv.fs_readlink(from)
    if not target then
      return false, err
    end
    return uv.fs_symlink(target, to)
  elseif stat.type ~= "directory" then
    return uv.fs_copyfile(from, to, { excl = true })
  end

  local ok, err = uv.fs_mkdir(to, stat.mode)
  for name in vim.fs.dir(from) do
    if not ok then
      break
    end
    ok, err = M.copy(from .. "/" .. name, to .. "/" .. name)
  end
  return ok, err
end

function M.move(from, to)
  if M.exists(to) then
    return false, "already exists"
  end
  make_parent(to)
  local ok, err, code = uv.fs_rename(from, to)
  if code == "EXDEV" then
    -- Across file systems: copy, then delete.
    ok, err = M.copy(from, to)
    if ok then
      ok = vim.fn.delete(from, "rf") == 0
      err = "copied, but could not delete the original"
    end
  end
  return ok, err
end

local function trash_dir()
  return vim.fn.stdpath("data") .. "/files.nvim/trash"
end

function M.delete(path)
  if not config.options.trash then
    return vim.fn.delete(path, "rf") == 0, "delete failed"
  end
  -- Unique names, so deleting a.txt twice keeps both.
  local to = ("%s/%s.%d"):format(
    trash_dir(),
    vim.fs.basename(path),
    uv.hrtime()
  )
  return M.move(path, to)
end

return M
