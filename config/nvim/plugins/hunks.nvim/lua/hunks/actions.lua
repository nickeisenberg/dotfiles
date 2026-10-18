-- What you do with the hunks of the current buffer: jump, preview, reset,
-- stage and unstage them, diff the whole file, and blame a line.
--
-- A `range` is { line1, line2 } in either order, e.g. from visual mode;
-- the hunks are then cut down to those lines. Without one, the action is
-- on the whole hunk under the cursor.

local buffer = require("hunks.buffer")
local config = require("hunks.config")
local diff = require("hunks.diff")
local git = require("hunks.git")

local M = {}

local warn = config.warn

-- Floats close when the cursor moves; calling the same action again
-- enters its float.
local function float(lines, syntax, id)
  vim.lsp.util.open_floating_preview(
    lines,
    syntax,
    { border = "rounded", focus_id = "hunks_" .. id }
  )
end

-- The current buffer's state with hunks up to date, or nil after a warning.
local function tracked()
  local state, why = buffer.current(vim.api.nvim_get_current_buf())
  if not state then
    warn(why)
  end
  return state
end

-- The hunks an action is on, or nil after a warning.
local function chosen(state, range)
  local found
  if range then
    local first, last =
      math.min(range[1], range[2]), math.max(range[1], range[2])
    found = diff.within(state.hunks, first, last, true)
  else
    local lnum = vim.fn.line(".")
    found = diff.within(state.hunks, lnum, lnum, false)
  end
  if #found == 0 then
    warn(range and "no hunks in the range" or "no hunk on this line")
    return nil
  end
  return found
end

local function base_lines(state, h)
  return vim.list_slice(state.base, h.old_start + 1, h.old_start + h.old_count)
end

-- Jump `count` hunks forward or back, wrapping with 'wrapscan'.
---@param forward boolean
---@param count? integer defaults to the count typed before the mapping
function M.nav(forward, count)
  local state = tracked()
  if not state then
    return
  end
  local starts = vim.tbl_map(function(h)
    return (diff.span(h))
  end, state.hunks)
  if #starts == 0 then
    warn("no hunks")
    return
  end

  local lnum, index = vim.fn.line("."), nil
  for _ = 1, math.max(count or vim.v.count1, 1) do
    index = nil
    if forward then
      for i = 1, #starts do
        if starts[i] > lnum then
          index = i
          break
        end
      end
    else
      for i = #starts, 1, -1 do
        if starts[i] < lnum then
          index = i
          break
        end
      end
    end
    if not index and vim.o.wrapscan then
      index = forward and 1 or #starts
    end
    if not index then
      warn("no more hunks " .. (forward and "below" or "above"))
      return
    end
    lnum = starts[index]
  end

  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.cmd("normal! ^")
  vim.api.nvim_echo({ { ("Hunk %d of %d"):format(index, #starts) } }, false, {})
end

-- The hunk under the cursor as a diff, in a float.
function M.preview()
  local state = tracked()
  local found = state and chosen(state)
  if not found then
    return
  end
  local h = found[1]
  -- Header numbers are git's: 1-based, or with a count of 0, the line
  -- the change comes after.
  local lines = {
    ("@@ -%d,%d +%d,%d @@"):format(
      h.old_count == 0 and h.old_start or h.old_start + 1,
      h.old_count,
      h.new_count == 0 and h.new_start or h.new_start + 1,
      h.new_count
    ),
  }
  for _, l in ipairs(base_lines(state, h)) do
    lines[#lines + 1] = "-" .. l
  end
  local new =
    vim.api.nvim_buf_get_lines(0, h.new_start, h.new_start + h.new_count, false)
  for _, l in ipairs(new) do
    lines[#lines + 1] = "+" .. l
  end
  float(lines, "diff", "preview")
end

-- Put back the base's lines; `u` undoes it.
---@param range? integer[]
function M.reset(range)
  local state = tracked()
  local found = state and chosen(state, range)
  if not found then
    return
  end
  if not vim.bo.modifiable then
    warn("the buffer is not modifiable")
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  -- From the bottom up, so the hunks above keep their line numbers.
  for i = #found, 1, -1 do
    local h = found[i]
    vim.api.nvim_buf_set_lines(
      bufnr,
      h.new_start,
      h.new_start + h.new_count,
      false,
      base_lines(state, h)
    )
  end
  buffer.update(bufnr)
end

-- Staging writes no patch: the file's index entry is pointed at new
-- content, the index version with the hunks applied, stored with `git
-- hash-object -w`. So the buffer needn't be saved.

-- root/relpath -> { { mode, before, after } }: the objects each stage
-- replaced and set, oldest first.
local undo = {}

-- The file's index entry: mode, object. nil when it has none.
local function index_entry(state)
  -- Literal, or a name like [0-9].txt would match 1.txt too.
  local out = git.run(
    state.root,
    { "ls-files", "--stage", "--", ":(literal)" .. state.relpath }
  )
  return (out or ""):match("^(%d+) (%x+) 0\t")
end

local function set_entry(state, mode, object)
  return git.run(state.root, {
    "update-index",
    "--cacheinfo",
    ("%s,%s,%s"):format(mode, object, state.relpath),
  })
end

---@param range? integer[]
function M.stage(range)
  local state = tracked()
  if not state then
    return
  end
  if state.base_name ~= "index" then
    warn(
      ("staging needs the index as the base, not %s (:Hunks base index)"):format(
        state.base_name
      )
    )
    return
  end
  local found = chosen(state, range)
  if not found then
    return
  end
  local mode, before = index_entry(state)
  if not mode then
    warn("the file has no index entry to stage into")
    return
  end
  -- The hunks are against the base as fetched; if the index has moved on
  -- since (in the same instant, so the stamp missed it), staging them would
  -- undo that change.
  local blob = git.run(state.root, { "hash-object", "--stdin" }, state.blob)
  if vim.trim(blob or "") ~= before then
    buffer.refresh(vim.api.nvim_get_current_buf(), true)
    warn("the index changed; signs updated, try again")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = buffer.lines(bufnr, state)
  local staged = diff.apply(state.base, lines, found)
  -- The last line ends as the base's does, unless the last hunk reaches
  -- the end of both: then as the buffer would be written.
  local eol = state.eol
  local last = found[#found]
  if
    last.old_start + last.old_count == #state.base
    and last.new_start + last.new_count == #lines
  then
    eol = vim.bo.endofline or vim.bo.fixendofline
  end
  local nl = state.crlf and "\r\n" or "\n"
  local text = table.concat(staged, nl) .. ((eol and #staged > 0) and nl or "")

  local hash, err =
    git.run(state.root, { "hash-object", "-w", "--stdin" }, text)
  if hash then
    hash = vim.trim(hash)
    err = select(2, set_entry(state, mode, hash))
  end
  if err then
    warn("git failed: " .. err)
    return
  end
  local key = state.root .. "/" .. state.relpath
  undo[key] = undo[key] or {}
  table.insert(undo[key], { mode = mode, before = before, after = hash })
  buffer.refresh(bufnr, true)
  vim.api.nvim_echo({
    { ("hunks: staged %d hunk%s"):format(#found, #found == 1 and "" or "s") },
  }, false, {})
end

-- Put back the index entry from before the last stage of this file.
function M.undo_stage()
  local state = tracked()
  if not state then
    return
  end
  local key = state.root .. "/" .. state.relpath
  local stack = undo[key] or {}
  local entry = stack[#stack]
  if not entry then
    warn("nothing staged here to undo")
    return
  end
  -- A `git add` or commit since then would be lost.
  local _, current = index_entry(state)
  if current ~= entry.after then
    undo[key] = nil
    warn("the index changed since the last stage; nothing to undo")
    return
  end
  local _, err = set_entry(state, entry.mode, entry.before)
  if err then
    warn("git failed: " .. err)
    return
  end
  stack[#stack] = nil
  buffer.refresh(vim.api.nvim_get_current_buf(), true)
  vim.api.nvim_echo({ { "hunks: unstaged" } }, false, {})
end

-- The base in a split on the left, in diff mode with the buffer. Closing
-- it turns diff mode off again.
function M.diffthis()
  local state = tracked()
  if not state then
    return
  end
  local win = vim.api.nvim_get_current_win()
  local filetype = vim.bo.filetype

  vim.cmd("vertical leftabove new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, state.base)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = filetype
  pcall(
    vim.api.nvim_buf_set_name,
    buf,
    ("hunks://%s/%s"):format(state.base_name, state.relpath)
  )
  vim.cmd.diffthis()
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_call(win, vim.cmd.diffoff)
      end
    end,
  })

  vim.api.nvim_set_current_win(win)
  vim.cmd.diffthis()
end

-- Who last changed the cursor line, and the full commit message, in a
-- float. The buffer is blamed as it is, so unsaved changes show as not
-- committed yet.
function M.blame()
  local state = tracked()
  if not state then
    return
  end
  -- With the file's line endings, so unchanged lines match committed ones.
  local nl = state.crlf and "\r\n" or "\n"
  local contents = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), nl)
    .. (vim.bo.endofline and nl or "")
  local lnum = vim.fn.line(".")
  local out, err = git.run(state.root, {
    "blame",
    "--porcelain",
    "-L",
    ("%d,%d"):format(lnum, lnum),
    "--contents",
    "-",
    "--",
    state.relpath,
  }, contents)
  if not out then
    warn("git blame failed: " .. err)
    return
  end

  -- The first line is the commit, then "key value" lines up to the line's
  -- text, which starts with a tab.
  local commit = out:match("^%x+")
  local info = {}
  for line in vim.gsplit(out, "\n", { plain = true }) do
    if line:sub(1, 1) == "\t" then
      break
    end
    local key, value = line:match("^(%S+) (.*)$")
    if key then
      info[key] = value
    end
  end

  local lines
  if not commit or commit:match("^0+$") then
    lines = { "Not committed yet" }
  else
    lines = {
      ("%s  %s  %s"):format(
        commit:sub(1, 8),
        info.author or "?",
        os.date("%Y-%m-%d %H:%M", tonumber(info["author-time"]) or 0)
      ),
      "",
    }
    local message = git.run(state.root, { "show", "-s", "--format=%B", commit })
      or ""
    vim.list_extend(lines, vim.split(vim.trim(message), "\n", { plain = true }))
  end
  float(lines, "", "blame")
end

return M
