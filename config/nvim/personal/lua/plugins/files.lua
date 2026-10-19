return {
  dir = "files.nvim",
  config = function()
    require("files").setup({
      show_hidden = true,
      trash = true, -- deleted entries go to stdpath("data")/files.nvim/trash
      git = true, -- `git status --short` letters in the sign column
      -- Buffer-local keys in a directory buffer; set one to false to drop it.
      keymaps = {
        ["<CR>"] = "select", -- open the file or directory under the cursor
        ["-"] = "parent",
        ["_"] = "cwd",
        ["g."] = "toggle_hidden",
        ["<C-l>"] = "refresh",
        ["<C-p>"] = "preview", -- toggle a split showing the entry under the cursor
        ["<C-s>"] = "select_vsplit",
        ["<C-h>"] = "select_split",
        ["<C-t>"] = "select_tab",
        ["<C-c>"] = "close", -- back to the buffer you opened it from
      },
    })
    vim.keymap.set("n", "<leader>O", "<CMD>Files<CR>", { desc = "Files" })
  end,
}
