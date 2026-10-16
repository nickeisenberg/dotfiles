-- Highlight groups, built from the colorscheme's own colors so they fit
-- whichever one is active. Recomputed whenever the colorscheme changes.

local M = {}

local function get(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

function M.setup()
  local pmenu_sel = get("PmenuSel")
  local directory = get("Directory")
  local visual = get("Visual")

  vim.api.nvim_set_hl(0, "StlMode", { fg = pmenu_sel.fg, bg = visual.bg })
  vim.api.nvim_set_hl(0, "StlGit", { fg = directory.fg, bg = pmenu_sel.bg })
end

return M
