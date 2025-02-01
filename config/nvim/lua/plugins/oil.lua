return {
  'stevearc/oil.nvim',
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("oil").setup({
      view_options = {
        show_hidden = true
      },
      columns = {
        "icon",        -- Show file type icons
        "permissions", -- Show file permissions
        "size",        -- Show file size
        "mtime",       -- Show modified time
        "git_status",  -- Show Git status (modified, added, conflicts, etc.)
      },
    })
    vim.keymap.set("n", "<space>O", "<cmd>Oil<cr>")
  end
}
