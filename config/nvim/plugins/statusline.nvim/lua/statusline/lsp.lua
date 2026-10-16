-- What the language servers attached to a buffer are doing.
--
-- Progress arrives through the LspProgress event and is kept per client
-- until the server reports the work done. vim.lsp.status() isn't used: it
-- consumes the messages, so with several windows only the first drawn
-- would see them.

local M = {}

-- client id -> "title message 40%", while that client reports progress.
local progress = {}

---@param ev table the LspProgress autocmd event
function M.on_progress(ev)
  local value = vim.tbl_get(ev, "data", "params", "value") or {}
  local id = ev.data.client_id

  if value.kind == "end" then
    progress[id] = nil
    return
  end

  local parts = { value.title, value.message }
  if value.percentage then
    parts[#parts + 1] = value.percentage .. "%"
  end
  progress[id] = table.concat(
    vim.tbl_filter(function(p)
      return p and p ~= ""
    end, parts),
    " "
  )
end

---@param ev table the LspDetach autocmd event
function M.on_detach(ev)
  progress[ev.data.client_id] = nil
end

-- "lua_ls: Indexing 40%" while a server works, else "ty, ruff", or "".
---@param bufnr integer
---@return string
function M.status(bufnr)
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if progress[client.id] then
      return client.name .. ": " .. progress[client.id]
    end
    names[#names + 1] = client.name
  end
  return table.concat(names, ", ")
end

return M
