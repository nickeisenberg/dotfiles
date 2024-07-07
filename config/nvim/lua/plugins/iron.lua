return {
  -- "Vigemus/iron.nvim",
  dir = "~/GitRepos/iron.nvim/iron.nvim",
  -- dir = "~\\GitRepos\\iron.nvim",
  -- "nickeisenberg/iron.nvim",
  branch = "master",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    local this_os = require("utils").get_os_name()

    local python_repl_definition
    if this_os == "Darwin" then
      python_repl_definition = {
        command = { "ipython", "--no-autoindent" },
        format = require("iron.fts.common").bracketed_paste_python
      }
    else
      python_repl_definition = nil
    end

    iron.setup {
      config = {
        scratch_repl = true,
        repl_open_cmd = view.split.vertical.rightbelow("%40"),
        repl_definition = {
          python = python_repl_definition,
        }
      },
      keymaps = {
        send_line = "<space>sl",
        visual_send = "<space>sp",
        send_paragraph = "<space>sp",
        send_until_cursor = "<space>su",
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
