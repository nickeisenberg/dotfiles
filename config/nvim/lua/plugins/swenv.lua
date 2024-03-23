return {
  "AckslD/swenv.nvim",
  config = function()
    require('swenv').setup({
      get_venvs = function(venvs_path)
        return require('swenv.api').get_venvs(venvs_path)
      end,
      -- venvs_path = vim.fn.expand(''),
      post_set_venv = nil,
    })

    local function listPy311EnvsAndSource()
      local settings = require('swenv.config').settings
      settings.venvs_path = vim.fn.expand('~/.venv311')
      require('swenv.api').pick_venv()
      vim.cmd('LspRestart')
    end
    vim.api.nvim_create_user_command('Venv311', listPy311EnvsAndSource, {})

    local function listPy310EnvsAndSource()
      local settings = require('swenv.config').settings
      settings.venvs_path = vim.fn.expand('~/.venv310')
      require('swenv.api').pick_venv()
      vim.cmd('LspRestart')
    end
    vim.api.nvim_create_user_command('Venv310', listPy310EnvsAndSource, {})

  end
}
