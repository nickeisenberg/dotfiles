-- The pieces of the statusline. Each takes the buffer shown in the window
-- being drawn and returns statusline text, "" when it has nothing to show.
--
-- Text taken from buffers and git goes through esc(): a "%" in it would
-- otherwise be read as a statusline item.

local config = require("statusline.config")
local git = require("statusline.git")
local lsp = require("statusline.lsp")

local M = {}

local function esc(text)
  return (text:gsub("%%", "%%%%"))
end

local MODES = {
  n = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "V-LINE",
  ["\22"] = "V-BLOCK",
  c = "COMMAND",
  t = "TERMINAL",
  R = "REPLACE",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
}

function M.mode()
  local mode = vim.api.nvim_get_mode().mode
  local label = MODES[mode] or MODES[mode:sub(1, 1)] or mode:upper()
  return "%#StlMode# " .. label .. " %*"
end

-- A file buffer's absolute path, or nil for special and unnamed buffers.
local function file_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or vim.bo[bufnr].buftype ~= "" then
    return nil
  end
  return name
end

function M.branch(bufnr)
  local path = file_path(bufnr)
  local root = path and git.root(path)
  local branch = root and git.branch(root)
  return branch and ("%#StlGit# " .. esc(branch) .. " %*") or ""
end

-- Lines added, changed and removed, as counted by gitsigns.
function M.diff(bufnr)
  local counts = vim.b[bufnr].gitsigns_status_dict
  if not counts then
    return ""
  end

  local out = {}
  for _, d in ipairs({
    { counts.added, "+", "Added" },
    { counts.changed, "~", "Changed" },
    { counts.removed, "-", "Removed" },
  }) do
    if d[1] and d[1] > 0 then
      out[#out + 1] = "%#" .. d[3] .. "#" .. d[2] .. d[1] .. "%*"
    end
  end
  return table.concat(out, " ")
end

-- The path relative to its repository, else to home; special buffers use
-- Neovim's own name for them. Then [+] when modified, [RO] when read-only.
function M.path(bufnr)
  local path = file_path(bufnr)
  local shown = "%f"
  if path then
    local root = git.root(path)
    shown = esc(root and path:sub(#root + 2) or vim.fn.fnamemodify(path, ":~"))
  end
  return shown .. "%( %m%r%)"
end

local SEVERITIES = {
  { vim.diagnostic.severity.ERROR, "error", "DiagnosticError" },
  { vim.diagnostic.severity.WARN, "warn", "DiagnosticWarn" },
  { vim.diagnostic.severity.INFO, "info", "DiagnosticInfo" },
  { vim.diagnostic.severity.HINT, "hint", "DiagnosticHint" },
}

function M.diagnostics(bufnr)
  local counts = vim.diagnostic.count(bufnr)
  local icons = config.options.icons
  local out = {}
  for _, s in ipairs(SEVERITIES) do
    local n = counts[s[1]]
    if n and n > 0 then
      out[#out + 1] = "%#" .. s[3] .. "#" .. icons[s[2]] .. n .. "%*"
    end
  end
  return table.concat(out, " ")
end

function M.lsp(bufnr)
  return esc(lsp.status(bufnr))
end

function M.filetype(bufnr)
  return esc(vim.bo[bufnr].filetype)
end

function M.position()
  return "%l:%c"
end

return M
