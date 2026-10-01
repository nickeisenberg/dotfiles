local M = {}

function M.get_os_name()
  return vim.uv.os_uname().sysname
end

function M.is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

return M
