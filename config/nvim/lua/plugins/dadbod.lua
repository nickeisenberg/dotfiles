-- See the following link for the setup
-- https://www.reddit.com/r/neovim/comments/1am7kym/how_to_get_dadbod_autocompletion_to_work_on_my/

return {
  "kristijanhusak/vim-dadbod-completion",
  dependencies = {
    "tpope/vim-dadbod",
    "kristijanhusak/vim-dadbod-ui",
  },
  config = function()
    local cmp = require "cmp"

    vim.api.nvim_create_autocmd(
      "FileType",
      {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          cmp.setup.buffer {
            sources = {
              { name = 'vim-dadbod-completion' }
            }
          }
        end,
      }
    )

    vim.cmd("let g:db_ui_execute_on_save = 0")

    local function _DBConfigSaveRoot(newSaveLocation)
      vim.cmd("let g:db_ui_save_location = '" .. newSaveLocation .. "'")
    end

    vim.api.nvim_create_user_command('DBConfigSaveLocation', function(input)
      local newLocation = input.args
      if newLocation == "" then
        newLocation = vim.fn.getcwd()
      end
      _DBConfigSaveRoot(newLocation)
    end, {nargs = '?'})
  end
}
