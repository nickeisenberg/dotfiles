-- Hunks between the base and the buffer.
--
-- A hunk is { old_start, old_count, new_start, new_count }, 0-based like
-- nvim_buf_set_lines(): base lines [old_start, old_start + old_count)
-- became buffer lines [new_start, new_start + new_count). When a count is
-- 0, its start is where lines were added or removed.

local M = {}

---@param base string
---@param text string
function M.hunks(base, text)
  -- vim.text.diff's starts are 1-based, or with a count of 0, the line the
  -- change comes after: that is already the 0-based position.
  return vim.tbl_map(function(h)
    return {
      old_start = h[2] == 0 and h[1] or h[1] - 1,
      old_count = h[2],
      new_start = h[4] == 0 and h[3] or h[3] - 1,
      new_count = h[4],
    }
  end, vim.text.diff(base, text, { result_type = "indices" }))
end

-- The buffer lines a hunk shows on, 1-based. Removed lines show on the
-- line above them, or line 1 when nothing is above.
---@return integer first, integer last
function M.span(h)
  if h.new_count == 0 then
    local lnum = math.max(h.new_start, 1)
    return lnum, lnum
  end
  return h.new_start + 1, h.new_start + h.new_count
end

-- The part of a hunk on buffer lines first..last. Added lines are
-- paired with removed ones by position, as in a changed line; the removed
-- lines past the end go with the hunk's last line.
local function cut(h, first, last)
  if h.new_count == 0 then
    return h
  end
  local a = math.max(first - 1, h.new_start) - h.new_start
  local b = math.min(last, h.new_start + h.new_count) - h.new_start
  local old_a = math.min(a, h.old_count)
  local old_b = b == h.new_count and h.old_count or math.min(b, h.old_count)
  return {
    old_start = h.old_start + old_a,
    old_count = old_b - old_a,
    new_start = h.new_start + a,
    new_count = b - a,
  }
end

-- The hunks on buffer lines first..last. With `partial`, each is cut down
-- to the part on those lines.
function M.within(hunks, first, last, partial)
  local found = {}
  for _, h in ipairs(hunks) do
    local s, e = M.span(h)
    if s <= last and e >= first then
      found[#found + 1] = partial and cut(h, first, last) or h
    end
  end
  return found
end

-- The base's lines with `hunks` taken from the buffer's `lines`.
function M.apply(base, lines, hunks)
  local out, pos = {}, 0
  for _, h in ipairs(hunks) do
    vim.list_extend(out, base, pos + 1, h.old_start)
    vim.list_extend(out, lines, h.new_start + 1, h.new_start + h.new_count)
    pos = h.old_start + h.old_count
  end
  return vim.list_extend(out, base, pos + 1, #base)
end

return M
