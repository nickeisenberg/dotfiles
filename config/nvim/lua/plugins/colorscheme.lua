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

M.lackluster = {
    "slugbyte/lackluster.nvim",
    lazy = false,
    priority = 1000,
    init = function()
        vim.cmd.colorscheme("lackluster")
        -- vim.cmd.colorscheme("lackluster-hack") -- my favorite
        -- vim.cmd.colorscheme("lackluster-mint")
    end,
}

return M.vague
