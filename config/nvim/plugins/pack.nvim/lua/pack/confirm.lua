-- Adding commit messages to the vim.pack update confirmation buffer.

local M = {}

local function commit_message(path, sha)
  local res = vim
    .system({ "git", "-C", path, "log", "-1", "--format=%s (%cr)", sha })
    :wait()
  if res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout)
end

-- Add a "Message:" line under every "Revision...:" line of the vim.pack
-- confirmation buffer. Only `#` and `##` headers matter when it is written,
-- so the extra lines are safe.
local function add_commit_messages(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local out, path = {}, nil

  for _, line in ipairs(lines) do
    out[#out + 1] = line
    path = line:match("^Path:%s+(.+)$") or path

    local label, sha = line:match("^(Revision[^:]*:%s+)(%x+)")
    local msg = label and path and commit_message(path, sha)
    if msg then
      local suffix = label:match("^Revision([^:]*):")
      local width = "%-" .. #label .. "s"
      out[#out + 1] = width:format("Message" .. suffix .. ":") .. msg
    end
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false
end

---Decorate the next confirmation buffer vim.pack opens.
function M.decorate_next()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "nvim-pack",
    once = true,
    callback = function(ev)
      add_commit_messages(ev.buf)
    end,
  })
end

return M
