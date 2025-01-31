local M =  {
  dir = "~/gitrepos/base.nvim",
  opts = {}
}

if require("utils").get_os_name() == "Darwin" then
  return {}
else
  return M
end
