require("codex").setup({
  backend = "terminal", -- "terminal" or "app_server"
  cmd = { "codex" },
  env = {}, -- passed to terminal and app-server processes

  -- "root", "file", "nvim", a directory path, or function(ctx)
  cwd = "nvim",
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
    hint = false,
    keymaps = { ask = "<leader>ga", edit = "<leader>ge" },
  },

  app_server = {
    cmd = { "codex", "app-server" },
  },
})

vim.keymap.set("n", "<leader>gg", "<cmd>Codex<cr>", {
  desc = "Toggle Codex",
})

vim.keymap.set("n", "<leader>gr", "<cmd>CodexResume<cr>", {
  desc = "Resume Codex",
})

vim.keymap.set("n", "<leader>gC", "<cmd>CodexContinue<cr>", {
  desc = "Continue Codex",
})

vim.keymap.set("n", "<leader>gk", "<cmd>CodexStop<cr>", {
  desc = "Stop Codex",
})

vim.keymap.set("n", "<leader>gb", "<cmd>CodexAdd<cr>", {
  desc = "Add current buffer",
})

vim.keymap.set("v", "<leader>gs", "<cmd>CodexSendVisual<cr>", {
  desc = "Send to Codex",
})

vim.keymap.set("n", "<leader>gt", "<cmd>CodexTreeAdd<cr>", {
  desc = "Add file to Codex",
})

vim.keymap.set("n", "<leader>ga", "<cmd>CodexAsk<cr>", {
  desc = "Ask Codex",
})

vim.keymap.set("v", "<leader>ge", "<cmd>CodexEdit<cr>", {
  desc = "Edit with Codex",
})
