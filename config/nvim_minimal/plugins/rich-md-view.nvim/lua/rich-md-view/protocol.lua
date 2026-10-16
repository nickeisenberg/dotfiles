-- Neovim side of the viewer protocol; python/mdview_protocol.py documents it.
-- Every message is "<kind> <args...> <nbytes>\n<payload>".

local M = {}

---@class RichMdView.Message
---@field kind string
---@field args string[]
---@field payload string

---@param kind string
---@param args any[]
---@param payload? string
---@return string
local function encode(kind, args, payload)
  payload = payload or ""
  local header = { kind }
  vim.list_extend(header, args)
  table.insert(header, #payload)
  return table.concat(header, " ") .. "\n" .. payload
end

---New buffer text, with the directory relative image paths resolve against.
---@param cursor integer 1-based source line
---@param dir string
---@param text string
function M.text(cursor, dir, text)
  return encode("T", { cursor, #dir }, dir .. text)
end

---@param cursor integer 1-based source line
function M.cursor(cursor)
  return encode("C", { cursor })
end

---@param rows integer|"top"|"bottom"
function M.scroll(rows)
  return encode("S", { rows })
end

---Returns feed(data), which buffers socket reads and returns the messages
---completed so far.
---@return fun(data: string): RichMdView.Message[]
function M.decoder()
  local buf = ""
  return function(data)
    buf = buf .. data
    local messages = {}
    while true do
      local nl = buf:find("\n", 1, true)
      if not nl then
        break
      end
      local args = vim.split(buf:sub(1, nl - 1), " ", { plain = true })
      local kind = table.remove(args, 1)
      local size = tonumber(table.remove(args))
      if #buf - nl < size then
        break
      end
      table.insert(messages, {
        kind = kind,
        args = args,
        payload = buf:sub(nl + 1, nl + size),
      })
      buf = buf:sub(nl + size + 1)
    end
    return messages
  end
end

return M
