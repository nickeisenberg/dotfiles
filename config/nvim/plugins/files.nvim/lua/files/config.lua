-- Options.

local M = {}

M.defaults = {
  show_hidden = true, -- dotfiles; g. toggles
  -- Deleted entries are moved to stdpath("data")/files.nvim/trash instead
  -- of being removed for good.
  trash = true,
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
}

M.options = vim.deepcopy(M.defaults)

---@param opts? table
function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.defaults, opts)
  -- Keys given replace the defaults, so renaming one doesn't keep the old.
  if opts.keymaps then
    M.options.keymaps = opts.keymaps
  end
  return M.options
end

function M.notify(msg, level)
  vim.notify("files: " .. msg, level or vim.log.levels.INFO)
end

return M
