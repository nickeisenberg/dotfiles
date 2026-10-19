-- Saving: what the edited directory buffers mean for the file system,
-- confirmed, then done.
--
-- Every modified buffer is read at once, so a line cut from one directory
-- and pasted in another is a move. Each line's number names the path it
-- came from:
--
--   a number gone from its buffer       delete
--   a line without a number             create (a trailing / for a directory)
--   a number under a new name           rename, or move in another directory
--   a number that is also still there   copy

local config = require("files.config")
local fs = require("files.fs")
local git = require("files.git")
local index = require("files.index")
local view = require("files.view")

local M = {}

local function join(dir, name)
  return dir == "/" and "/" .. name or dir .. "/" .. name
end

local function inside(path, dir)
  return vim.startswith(path, dir .. "/")
end

-- The changes in the modified buffers: { from?, to?, dir }, from being a
-- path that exists now and to the path it should be at.
local function changes(bufnrs)
  local found, kept = {}, {}
  for _, bufnr in ipairs(bufnrs) do
    local dir = view.dir(bufnr)
    for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
      local entry = view.parse(line)
      if entry and not entry.parent then
        local from = entry.id and index.path(entry.id)
        local to = join(dir, entry.name)
        if from == to and not kept[from] then
          kept[from] = true
        else
          found[#found + 1] = { from = from, to = to, dir = entry.dir }
        end
      end
    end
    for _, id in ipairs(view.state(bufnr).ids) do
      local path = index.path(id)
      if path and not kept[path] then
        found[#found + 1] = { from = path }
      end
    end
  end
  return found
end

-- The actions for the changes, in a safe order, or nil and why not.
local function plan(found)
  local deleted, creates, moves, copies = {}, {}, {}, {}
  for _, c in ipairs(found) do
    if not c.to then
      deleted[c.from] = true
    end
  end

  for _, c in ipairs(found) do
    if c.to and not c.from then
      creates[#creates + 1] = { action = "create", to = c.to, dir = c.dir }
    elseif c.to and deleted[c.from] then
      -- The first place a removed line went is where it moved; any other
      -- is a copy.
      deleted[c.from] = nil
      local same_dir = vim.fs.dirname(c.from) == vim.fs.dirname(c.to)
      moves[#moves + 1] =
        { action = same_dir and "rename" or "move", from = c.from, to = c.to }
    elseif c.to then
      copies[#copies + 1] = { action = "copy", from = c.from, to = c.to }
    end
  end

  -- Actions on what is inside a deleted directory go before the delete.
  local early, deletes, late = {}, {}, {}
  for path in pairs(deleted) do
    deletes[#deletes + 1] = { action = "delete", from = path }
  end
  table.sort(deletes, function(a, b)
    return a.from < b.from
  end)
  for _, list in ipairs({ moves, copies, creates }) do
    for _, a in ipairs(list) do
      local early_one = false
      for path in pairs(deleted) do
        early_one = early_one or (a.from and inside(a.from, path))
      end
      table.insert(early_one and early or late, a)
    end
  end
  local actions = vim.list_extend(vim.list_extend(early, deletes), late)

  -- Refuse what would overwrite, or can't work.
  local targets, sources = {}, {}
  for _, a in ipairs(moves) do
    sources[a.from] = true
  end
  for _, a in ipairs(actions) do
    local name = a.to and vim.fs.basename(a.to)
    if a.from and not fs.exists(a.from) then
      return nil, ("%s no longer exists"):format(a.from)
    elseif a.to and (name == "." or name == "..") then
      return nil, ("%q is not a valid name"):format(name)
    elseif a.to and targets[a.to] then
      return nil, ("two entries would be %s"):format(a.to)
    elseif a.to and sources[a.to] then
      return nil,
        ("%s is renamed and replaced at once; save in two steps"):format(a.to)
    elseif a.to and fs.exists(a.to) and not deleted[a.to] then
      return nil, ("%s already exists"):format(a.to)
    elseif a.from and a.to and inside(a.to, a.from) then
      return nil, ("can't put %s inside itself"):format(a.from)
    end
    if a.to then
      targets[a.to] = true
    end
  end
  return actions
end

local function describe(a)
  local function short(path)
    return vim.fn.fnamemodify(path, ":~:.")
  end
  local what = a.action:upper()
  if a.action == "delete" then
    return ("%-7s %s%s"):format(
      what,
      short(a.from),
      fs.to_trash(a.from) and "  (to trash)" or ""
    )
  elseif a.action == "create" then
    return ("%-7s %s%s"):format(what, short(a.to), a.dir and "/" or "")
  end
  return ("%-7s %s -> %s"):format(what, short(a.from), short(a.to))
end

-- Rename a buffer. Like :file, that leaves an unlisted buffer under the
-- old name behind, which would show up as the alternate file; wipe it.
local function set_name(bufnr, name)
  local old = vim.api.nvim_buf_get_name(bufnr)
  vim.api.nvim_buf_set_name(bufnr, name)
  -- Compared by name, not with bufnr(), which reads the name as a pattern.
  for _, left in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_get_name(left) == old
      and not vim.api.nvim_buf_is_loaded(left)
    then
      vim.api.nvim_buf_delete(left, { force = true })
    end
  end
end

-- Point open buffers of a moved file, or files in a moved directory, at
-- the new path.
local function rename_buffers(from, to)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if vim.bo[bufnr].buftype == "" and (name == from or inside(name, from)) then
      set_name(bufnr, to .. name:sub(#from + 1))
      if vim.bo[bufnr].modified then
        config.notify(
          ("%s has unsaved changes; :w! saves them at its new path"):format(
            vim.fn.fnamemodify(name, ":~:.")
          ),
          vim.log.levels.WARN
        )
      elseif vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("silent! edit")
        end)
      end
    end
  end
end

-- Later actions on what was at `from` find it at `to` now.
local function follow(actions, start, from, to)
  for i = start, #actions do
    local a = actions[i]
    for _, key in ipairs({ "from", "to" }) do
      local path = a[key]
      if path and (path == from or inside(path, from)) then
        a[key] = to .. path:sub(#from + 1)
      end
    end
  end
end

local run = {
  create = function(a)
    return fs.create(a.to, a.dir)
  end,
  delete = function(a)
    return fs.delete(a.from)
  end,
  copy = function(a)
    return fs.copy(a.from, a.to)
  end,
  move = function(a)
    return fs.move(a.from, a.to)
  end,
}
run.rename = run.move

-- Do the actions in order, stopping at the first that fails. Each one done
-- is marked `done`.
local function apply(actions)
  for i, a in ipairs(actions) do
    -- Vim functions like mkdir() throw rather than return false.
    local threw, ok, err = pcall(run[a.action], a)
    if not threw then
      ok, err = false, ok
    end
    a.done = ok
    if ok and (a.action == "move" or a.action == "rename") then
      index.moved(a.from, a.to)
      rename_buffers(a.from, a.to)
      follow(actions, i + 1, a.from, a.to)
    end
    if not ok then
      return false, ("%s failed: %s"):format(describe(a), err or "?")
    end
  end
  return true
end

-- After the changes, show every directory as it is now; a buffer of a
-- directory that moved follows it. Returns the buffers of directories that
-- are gone: { bufnr, dir }.
local function rerender(actions)
  local moved = {}
  for _, a in ipairs(actions) do
    if a.done and (a.action == "move" or a.action == "rename") then
      moved[#moved + 1] = a
    end
  end
  local gone = {}
  for _, bufnr in ipairs(view.list()) do
    local dir = view.dir(bufnr)
    for _, a in ipairs(moved) do
      if dir == a.from or inside(dir, a.from) then
        dir = a.to .. dir:sub(#a.from + 1)
        -- Fails if a buffer already has that name; then this one is gone.
        if not pcall(set_name, bufnr, view.name(dir)) then
          dir = ""
        end
      end
    end
    if fs.is_dir(dir) then
      view.render(bufnr)
      git.update(bufnr)
    else
      gone[#gone + 1] = { bufnr = bufnr, dir = dir }
    end
  end
  return gone
end

-- Save every modified directory buffer. Returns what rerender() does.
function M.save()
  local bufnrs = vim.tbl_filter(function(bufnr)
    return vim.bo[bufnr].modified
  end, view.list())
  local actions, err = plan(changes(bufnrs))
  if not actions then
    config.notify(err, vim.log.levels.ERROR)
    return {}
  end
  if #actions == 0 then
    return rerender({})
  end

  local lines = vim.tbl_map(describe, actions)
  local answer = vim.fn.confirm(table.concat(lines, "\n"), "&Yes\n&No", 2)
  if answer ~= 1 then
    return {}
  end
  local ok
  ok, err = apply(actions)
  local gone = rerender(actions)
  if not ok then
    config.notify(err, vim.log.levels.ERROR)
  end
  return gone
end

return M
