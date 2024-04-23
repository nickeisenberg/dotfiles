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


    local function find_git_root()
      local path = vim.fn.expand('%:p:h')
      local root_marker = '.git'

      while path ~= '/' and path ~= '' do
          if vim.fn.isdirectory(path .. '/' .. root_marker) ~= 0 then
              return path
          end
          path = vim.fn.fnamemodify(path, ':h')
      end
    end

    local function listPyEnvsInCWD()
      local settings = require('swenv.config').settings
      settings.venvs_path = vim.fn.getcwd()
      require('swenv.api').pick_venv()
      vim.cmd('LspRestart')
    end
    vim.api.nvim_create_user_command('VenvCWD', listPyEnvsInCWD, {})

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
