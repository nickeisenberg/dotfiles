local M = {}

M.rosepine = {
  "rose-pine/neovim",
  name = "rose-pine",
  config = function()
    require("rose-pine").setup({
      palette = {
        main = {
          base = "#121212",
		      surface = "#121212",
        }
      }
    })
    vim.cmd("colorscheme rose-pine")
  end
}

M.vague = {
  "vague2k/vague.nvim",
  config = function()
    require("vague").setup({
      -- optional configuration here
    })
    vim.cmd("colorscheme vague")
  end
}

M.default = {
  "vague2k/vague.nvim",
  config = function()
    vim.cmd("colorscheme default")
  end
}

return M.vague
