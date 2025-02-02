return {
  {
    'stevearc/oil.nvim',
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("oil").setup({
        view_options = {
          show_hidden = true
        },
        win_options = {
          signcolumn = "yes:2",
        },
      })
      vim.keymap.set("n", "<space>O", "<cmd>Oil<cr>")
    end
  },
  {
    "refractalize/oil-git-status.nvim",
    dependencies = {
      "stevearc/oil.nvim",
    },
    config = true
  }
}
