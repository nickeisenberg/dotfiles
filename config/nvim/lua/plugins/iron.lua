return {
  -- "Vigemus/iron.nvim",
  -- dir = "~/GitRepos/iron.nvim/iron.nvim",
  -- dir = "~\\GitRepos\\iron.nvim",
  -- branch = "master",
  "nickeisenberg/iron.nvim",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    local isWindows = require("iron.util.os").isWindows

    local repl_definition = {}
    if isWindows() then
      repl_definition = {
        python = {
          command = { "ipython", "--no-autoindent" }
        }
      }
    end

    iron.setup {
      config = {
        scratch_repl = true,
        repl_open_cmd = view.split.vertical.rightbelow("%40"),
        repl_definition = repl_definition
      },
      keymaps = {
        send_line = "<space>sl",
        visual_send = "<space>sp",
        send_paragraph = "<space>sp",
        send_file = "<space>sf",
        exit = "<space>rq",
        clear = "<space>rc",
        interrupt = "<space><c-c>",
        cr = "<space><cr>",
      },
      highlight = {
        italic = true
      },
      ignore_blank_lines = true,
    }

    vim.keymap.set('n', '<space>rr', '<cmd>IronRepl<cr>')
    vim.keymap.set('n', '<space>rR', '<cmd>IronRestart<cr>')

    local toggle_below = function()
      local config = require("iron.config")
      config.repl_open_cmd = view.split.rightbelow("%25")
      vim.cmd('IronRepl')
    end
    vim.keymap.set('n', '<space>rh', toggle_below, { silent = true })

    local toggle_right = function()
      local config = require("iron.config")
      config.repl_open_cmd = view.split.vertical.rightbelow("%40")
      vim.cmd('IronRepl')
    end
    vim.keymap.set('n', '<space>rv', toggle_right, { silent = true })
  end
}
