return {
  "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    config = function()
      require("chatgpt").setup({

      --   popup_layout = {
      --     default = "center",
      --     center = {
      --       width = "90%",
      --       height = "90%",
      --     },
      --     right = {
      --       width = "30%",
      --       width_settings_open = "50%",
      --     },
      --   },

      --   system_window = {
      --     size = {
      --       width = 200
      --     }
      --   },

    })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim"
    }
}
