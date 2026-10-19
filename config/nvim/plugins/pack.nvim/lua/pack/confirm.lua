-- Adding commit messages to the vim.pack update confirmation buffer.

local M = {}

local group = vim.api.nvim_create_augroup("pack_confirm", { clear = true })

-- Start one `git log` per "Revision...:" line, all at once, so a long
-- plugin list doesn't wait on each process in turn. Keyed by line number.
local function start_lookups(lines)
  local jobs, path = {}, nil

  for i, line in ipairs(lines) do
    path = line:match("^Path:%s+(.+)$") or path

    local label, sha = line:match("^(Revision[^:]*:%s+)(%x+)")
    if label and path then
      jobs[i] = {
        label = label,
        proc = vim.system({
          "git",
          "-C",
          path,
          "log",
          "-1",
          "--format=%s (%cr)",
          sha,
        }),
      }
    end
  end

  return jobs
end

-- Add a "Message:" line under every "Revision...:" line of the vim.pack
-- confirmation buffer. Only `#` and `##` headers matter when it is written,
-- so the extra lines are safe.
local function add_commit_messages(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local jobs = start_lookups(lines)
  local out = {}
  -- The lookups run at once, so they share one deadline; a hung git
  -- leaves its line without a message instead of freezing the editor.
  local deadline = vim.uv.hrtime() + 3e9

  for i, line in ipairs(lines) do
    out[#out + 1] = line

    local job = jobs[i]
    local left = math.max(0, math.floor((deadline - vim.uv.hrtime()) / 1e6))
    local res = job and job.proc:wait(left)
    if res and res.code == 0 then
      local suffix = job.label:match("^Revision([^:]*):")
      local width = "%-" .. #job.label .. "s"
      out[#out + 1] = width:format("Message" .. suffix .. ":")
        .. vim.trim(res.stdout)
    end
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false
end

---Decorate the next confirmation buffer vim.pack opens.
function M.decorate_next()
  -- vim.pack.update() can return without opening a buffer ("Nothing to
  -- update", or an error). Clearing the group keeps at most one pending
  -- autocmd, so a later buffer is never decorated twice.
  vim.api.nvim_clear_autocmds({ group = group })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "nvim-pack",
    once = true,
    callback = function(ev)
      add_commit_messages(ev.buf)
    end,
  })
end

return M
