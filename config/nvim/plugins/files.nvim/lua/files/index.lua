-- Every path shown gets a number, which each line starts with, hidden:
-- "/12 name". The number survives yanking and pasting, so on save a line
-- can be traced to the path it came from, whichever buffer it is in now.

local M = {}

local paths, ids = {}, {} -- id -> path, path -> id
local last = 0

---@param path string
---@return integer
function M.id(path)
  if not ids[path] then
    last = last + 1
    paths[last], ids[path] = path, last
  end
  return ids[path]
end

---@return string?
function M.path(id)
  return paths[id]
end

-- After a move, the entry keeps its number, so a line yanked before the
-- move still refers to it.
function M.moved(from, to)
  local id = ids[from]
  if not id then
    return
  end
  if ids[to] then
    paths[ids[to]] = nil
  end
  ids[from], ids[to], paths[id] = nil, id, to
end

return M
