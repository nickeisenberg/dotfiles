return {
  -- "Vigemus/iron.nvim",
  -- dir = "~/gitrepos/iron.nvim/iron.nvim",
  -- dir = "~\\GitRepos\\iron.nvim",
  "nickeisenberg/iron.nvim",
  branch = "dev",
  config = function()
    local iron = require("iron")
    local view = require("iron.view")
    local common = require("iron.fts.common")
    local OS = require("utils").get_os_name()

    iron.setup {
      config = {
        scratch_repl = true,
        repl_open_cmd = view.split.vertical.rightbelow("%40"),
        repl_definition = {
          python = {
            command = { "ipython", "--no-autoindent" } and OS == "Darwin" or { "python3" },
            format = common.bracketed_paste_python,
            block_deviders = { "# %%", "#%%" },
          }
        },
        repl_filetype = function(_, ft)
          return ft
        end,
      },
      keymaps = {
        send_line = "<space>sl",
        visual_send = "<space>sp",
        send_paragraph = "<space>sp",
        send_until_cursor = "<space>su",
        send_code_block = "<space>sb",
        send_code_block_and_move = "<space>sn",
        send_file = "<space>sf",
        exit = "<space>rq",
        clear = "<space>rc",
        interrupt = "<space><c-c>",
        cr = "<space><cr>",
        toggle_repl = "<space>rr",
        restart_repl = "<space>rR",
        toggle_repl_below = "<space>rh",
        toggle_repl_right = "<space>rv",
      },
      highlight = {
        italic = true
      },
      ignore_blank_lines = true,
    }

    -- vim.keymap.set('n', '<space>rr', '<cmd>IronRepl<cr>')
    -- vim.keymap.set('n', '<space>rR', '<cmd>IronRestart<cr>')

    -- local toggle_below = function()
    --   require("iron.config").repl_open_cmd = view.split.rightbelow("%25")
    --   vim.cmd('IronRepl')
    -- end
    -- vim.keymap.set('n', '<space>rh', toggle_below, { silent = true })

    -- local toggle_right = function()
    --   require("iron.config").repl_open_cmd = view.split.vertical.rightbelow("%40")
    --   vim.cmd('IronRepl')
    -- end
    -- vim.keymap.set('n', '<space>rv', toggle_right, { silent = true })
  end
}
