local M = {}

function M.get_os_name()
  return vim.uv.os_uname().sysname
end

return M
