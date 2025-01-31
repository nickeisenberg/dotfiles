return {
  "rose-pine/neovim",
  name = "rose-pine",
  config = function()
    -- local pine = require("rose-pine")
    -- pine.setup({
    --   palette = {
    --     main = {
    --       base = "#000000"
    --     }
    --   }
    -- })
    vim.cmd("colorscheme rose-pine")
  end
}
