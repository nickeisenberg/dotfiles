-- Images the viewer sends, uploaded to the host terminal with the kitty
-- graphics protocol. Freed when the viewer stops showing them, and the
-- rest together when the preview closes.

local kitty = require("rich-md-view.kitty")

local M = {}

---Whether the host terminal can show images. Warns when it could but isn't
---set up for it.
---@return boolean
function M.available()
  if not kitty.detect() then
    return false
  end
  local reason = kitty.check()
  if reason then
    vim.notify("rich-md-view: images disabled, " .. reason, vim.log.levels.WARN)
    return false
  end
  return true
end

---@class RichMdView.Images
---@field private ids table<integer, true> uploaded to the host terminal
local Images = {}
Images.__index = Images

---@return RichMdView.Images
function M.new()
  return setmetatable({ ids = {} }, Images)
end

---@param id integer
---@param png string
---@param rows integer
---@param cols integer
function Images:upload(id, png, rows, cols)
  kitty.render(id, png, rows, cols)
  self.ids[id] = true
end

---@param id integer
function Images:delete(id)
  pcall(kitty.delete, id)
  self.ids[id] = nil
end

---Frees every uploaded image.
function Images:clear()
  for id in pairs(self.ids) do
    pcall(kitty.delete, id)
  end
  self.ids = {}
end

return M
