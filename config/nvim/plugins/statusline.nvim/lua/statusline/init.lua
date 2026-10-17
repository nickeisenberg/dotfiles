-- A statusline: mode, branch, changes and path on the left; diagnostics,
-- language servers, filetype and position on the right.
--
-- 'statusline' is "%!v:lua.require'statusline'.render()". Neovim runs a
-- %! expression in the context of the *current* window, so render() reads
-- g:statusline_winid to draw each window from its own buffer.

local config = require("statusline.config")
local highlights = require("statusline.highlights")
local lsp = require("statusline.lsp")
local parts = require("statusline.parts")

local M = {}

-- Join the non-empty pieces with single spaces.
local function join(pieces)
  return table.concat(
    vim.tbl_filter(function(p)
      return p ~= ""
    end, pieces),
    " "
  )
end

---@return string
function M.render()
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(win)

  if win ~= vim.api.nvim_get_current_win() then
    return " " .. parts.path(bufnr)
  end

  local show = config.options.show
  local function part(name, ...)
    return show[name] and parts[name](...) or ""
  end

  local left = join({
    part("mode"),
    show.git and parts.branch(bufnr) or "",
    part("diff", bufnr),
    parts.path(bufnr),
  })
  -- Server names crowd out the path in a narrow window; leave them out.
  local wide = vim.api.nvim_win_get_width(win) >= 80
  local right = join({
    part("diagnostics", bufnr),
    wide and part("lsp", bufnr) or "",
    part("filetype", bufnr),
    part("position"),
  })
  -- The space after %= keeps the sides apart when the path is cut short.
  return left .. "%= " .. right .. " "
end

-- Redraw every statusline once, however many events asked in one tick.
local pending = false
local function redraw()
  if pending then
    return
  end
  pending = true
  vim.schedule(function()
    pending = false
    vim.cmd.redrawstatus({ bang = true })
  end)
end

---@param opts? table see statusline.config.defaults
function M.setup(opts)
  config.setup(opts)
  highlights.setup()

  -- Clearing the group makes calling setup() again safe.
  local group = vim.api.nvim_create_augroup("statusline", { clear = true })
  local function on(event, callback, pattern)
    vim.api.nvim_create_autocmd(event, {
      group = group,
      pattern = pattern,
      callback = callback,
    })
  end

  on("ColorScheme", highlights.setup)
  on("LspProgress", function(ev)
    lsp.on_progress(ev)
    redraw()
  end)
  on("LspDetach", function(ev)
    lsp.on_detach(ev)
    redraw()
  end)
  on({ "DiagnosticChanged", "LspAttach", "FocusGained" }, redraw)
  -- Changed-line counts follow edits.
  on({ "TextChanged", "TextChangedI", "BufWritePost" }, redraw)

  vim.o.statusline = "%!v:lua.require'statusline'.render()"
end

return M
