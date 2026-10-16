-- Options, and the notify helper every module shares.

local M = {}

M.defaults = {
  -- Lua module directory scanned for spec files.
  import = "plugins",
  -- Where relative `dir` paths of local plugins are resolved.
  local_dir = vim.fn.stdpath("config") .. "/plugins",
  -- Prefix for "owner/repo" shorthand.
  base_url = "https://github.com/",
}

M.options = vim.deepcopy(M.defaults)

---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.notify(msg, level)
  vim.notify("pack: " .. msg, level or vim.log.levels.INFO)
end

return M
