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

    -- Not ready
    -- See the source code for core.repl_for.
    -- Need to mess with the visability to toggle the repl
    local function _repl_below()
      local ft = vim.bo[vim.api.nvim_get_current_buf()].filetype
      local orig_win_height = vim.api.nvim_win_get_height(0)
      local new_win_height = math.floor(orig_win_height * 0.75)
      vim.cmd("split")
      vim.cmd("resize " .. new_win_height)
      vim.cmd("wincmd j")
      iron.repl_here(ft)
      vim.cmd("wincmd k")
    end
    vim.api.nvim_create_user_command('ReplBelow', _repl_below, {})

    vim.keymap.set('n', '<space>rb', ":ReplBelow <CR>")

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
      -- Introduce a slight delay before executing the next command
      vim.defer_fn(function()
        iron.visual_send()
      end, 100) -- Delay in milliseconds
    end, {silent = true})


    vim.keymap.set('n', '<space>rt', '<cmd>IronRepl<cr>')
    vim.keymap.set('n', '<space>rR', '<cmd>IronRestart<cr>')
  end
}
