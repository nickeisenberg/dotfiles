require("codex").setup({
  backend = "terminal", -- "terminal" or "app_server"
  cmd = { "codex" },
  env = {}, -- passed to terminal and app-server processes

  -- "root", "file", "nvim", a directory path, or function(ctx)
  cwd = function()
    return vim.fn.getcwd()
  end,
  root_markers = { ".git" },
  focus_after_send = false, -- applies to both backends

  terminal = {
    layout = "split", -- "split" or "float"
    split_side = "right",
    split_width_percentage = 0.35,
    float = {
      width_percentage = 0.85,
      height_percentage = 0.85,
      border = "rounded",
    },
    auto_insert = false,
    auto_close = true,
    hide_keys = {}, -- terminal-local keys that hide Codex
    normal_mode_keys = {}, -- terminal-local keys that enter Neovim Normal mode
    window_navigation = {
      left = "<M-h>",
      down = "<M-j>",
      up = "<M-k>",
      right = "<M-l>",
    },
  },

  context = {
    max_lines = 500,
    max_bytes = 65536,
  },

  selection = {
    enabled = true,
    hint = true,
    keymaps = { ask = "<leader>aa", edit = "<leader>aE" },
  },

  app_server = {
    cmd = { "codex", "app-server" },
  },
})
