local M = {}

M.rosepine = {
  "rose-pine/neovim",
  name = "rose-pine",
  config = function()
    vim.cmd("colorscheme rose-pine")
  end
}

M.vague = {
  "vague2k/vague.nvim",
  config = function()
    require("vague").setup({
      -- optional configuration here
    })
  end
}

return M.rosepine
