-- Per-buffer state: the file's text at the base, fetched again when the
-- index or HEAD moves, and the hunks between it and the buffer, diffed
-- again as you edit.

local config = require("hunks.config")
local diff = require("hunks.diff")
local git = require("hunks.git")
local signs = require("hunks.signs")

local M = {}

-- bufnr -> {
--   path, root, relpath   the file, its repository, its path in there
--   stamp, base_name      when the base was fetched, and at what base
--   base                  the base's lines (without CRs); nil while
--                         fetching, false when the file isn't at the base
--   base_text             the same, joined for vim.text.diff
--   blob                  the base as git stores it
--   eol, crlf             whether the base ends with a newline, and has
--                         CRLF line endings
--   hunks, tick           the hunks, and the changedtick they are for
--   placed                the hunks the signs show
-- }
local states = {}

M.enabled = true

local function path_of(bufnr)
  if vim.bo[bufnr].buftype ~= "" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  return vim.uv.fs_realpath(name) or vim.fs.normalize(name)
end

---@return string[]
function M.lines(bufnr, state)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- An empty buffer still has one empty line.
  if #state.base == 0 and #lines == 1 and lines[1] == "" then
    return {}
  end
  return lines
end

local function join(lines)
  return #lines == 0 and "" or table.concat(lines, "\n") .. "\n"
end

-- Diff again if the buffer changed since the last time.
local function diff_buffer(bufnr, state)
  local tick = vim.b[bufnr].changedtick
  if state.tick ~= tick then
    state.hunks = diff.hunks(state.base_text, join(M.lines(bufnr, state)))
    state.tick = tick
  end
end

function M.update(bufnr)
  local state = states[bufnr]
  if not (state and state.base and vim.api.nvim_buf_is_loaded(bufnr)) then
    return
  end
  diff_buffer(bufnr, state)
  if M.enabled and state.placed ~= state.hunks then
    signs.place(bufnr, state.hunks)
    state.placed = state.hunks
  end
end

function M.detach(bufnr)
  states[bufnr] = nil
  signs.clear(bufnr)
end

-- Update the signs after edits, at most every `debounce` ms per buffer.
local pending = {}
local function schedule(bufnr)
  if pending[bufnr] then
    return
  end
  pending[bufnr] = true
  vim.defer_fn(function()
    pending[bufnr] = nil
    M.update(bufnr)
  end, config.options.debounce)
end

-- Watch a buffer's edits, from typing or from Lua (formatters, LSP edits),
-- until it is no longer tracked.
local attached = {}
local function attach(bufnr)
  if attached[bufnr] then
    return
  end
  attached[bufnr] = vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function()
      if not states[bufnr] then
        attached[bufnr] = nil
        return true -- detach
      end
      schedule(bufnr)
    end,
    on_detach = function()
      attached[bufnr] = nil
    end,
  })
end

local function on_fetched(bufnr, state, text)
  if not text then
    -- Not at the base, e.g. untracked: no signs until the index or HEAD
    -- changes.
    state.base = false
    signs.clear(bufnr)
    return
  end
  local lines = text == "" and {} or vim.split(text, "\n", { plain = true })
  state.eol = text:sub(-1) == "\n"
  if state.eol then
    lines[#lines] = nil
  end
  -- A CRLF file stored as is; a 'fileformat' dos buffer has no CRs.
  state.crlf = vim.bo[bufnr].fileformat == "dos"
    and lines[1] ~= nil
    and lines[1]:sub(-1) == "\r"
  if state.crlf then
    lines = vim.tbl_map(function(l)
      return (l:gsub("\r$", ""))
    end, lines)
  end
  state.base = lines
  state.base_text = join(lines)
  state.blob = text
  M.update(bufnr)
end

-- Fetch the base if it may have changed (or with `force`), else just diff
-- again.
function M.refresh(bufnr, force)
  local path = path_of(bufnr)
  local root = path and git.root(path)
  if not root then
    M.detach(bufnr)
    return
  end

  attach(bufnr)

  local stamp = git.stamp(root)
  local base_name = config.options.base
  local old = states[bufnr]
  if
    not force
    and old
    and old.path == path
    and old.stamp == stamp
    and old.base_name == base_name
  then
    M.update(bufnr)
    return
  end

  -- A new table, so a fetch still running for the old one is ignored.
  local state = {
    path = path,
    root = root,
    relpath = path:sub(#root + 2),
    stamp = stamp,
    base_name = base_name,
  }
  states[bufnr] = state
  git.show(root, state.relpath, base_name, function(text)
    if states[bufnr] == state and vim.api.nvim_buf_is_valid(bufnr) then
      on_fetched(bufnr, state, text)
    end
  end)
end

function M.refresh_all(force)
  for bufnr in pairs(states) do
    M.refresh(bufnr, force)
  end
end

-- The buffer's state with hunks for its text as it is now, for the
-- commands. Fetches the base first if the index or HEAD moved, and waits up
-- to a second for that. Else nil and why.
---@return table?, string?
function M.current(bufnr)
  M.refresh(bufnr)
  vim.wait(1000, function()
    local s = states[bufnr]
    return not s or s.base ~= nil
  end, 5)
  local state = states[bufnr]
  if not (state and state.base) then
    if state and state.base == nil then
      return nil, "git is still reading the file, try again"
    end
    return nil, "this buffer is not tracked by git"
  end
  diff_buffer(bufnr, state)
  return state
end

function M.toggle()
  M.enabled = not M.enabled
  for bufnr in pairs(states) do
    if M.enabled then
      M.update(bufnr)
    else
      signs.clear(bufnr)
      states[bufnr].placed = nil
    end
  end
end

return M
