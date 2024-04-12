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
  end
}
