return {
  "Vigemus/iron.nvim",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")

    iron.setup {
      config = {
        scratch_repl = true,
        repl_definition = {
          sh = {
            command = { "bash" }
          }
        },
        repl_open_cmd = view.split.vertical.botright("%40"),
      },
      keymaps = {
        send_line = "<space>sl",
        visual_send = "<space>sv",
        send_file = "<space>sf",
        exit = "<space>rq",
        clear = "<space>rc",
      },
      highlight = {
        italic = true
      },
      ignore_blank_lines = true,
    }

    vim.keymap.set('n', '<space>rh', function()
      iron.setup(
        {
          config = {
            repl_open_cmd = view.split.botright("%25"),
          }
        }
      )
      vim.cmd('IronRepl')
    end, {silent = true})

    vim.keymap.set('n', '<space>rv', function()
      iron.setup(
        {
          config = {
            repl_open_cmd = view.split.vertical.botright("%40"),
          }
        }
      )
      vim.cmd('IronRepl')
    end, {silent = true})


    vim.keymap.set('n', '<space>sp', function()
      vim.cmd('normal! vip')
      iron.visual_send()
    end, {silent = true})


    vim.keymap.set('n', '<space>rt', '<cmd>IronRepl<cr>')
    vim.keymap.set('n', '<space>rR', '<cmd>IronRestart<cr>')
  end
}
