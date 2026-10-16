-- Options, and the notify helper every module shares.

local M = {}

M.defaults = {
  -- Sources in priority order. Earlier sources get more time and their
  -- items come first. Known names: "path", "snippets", "lsp", "buffer".
  sources = { "path", "snippets", "lsp", "buffer" },
  -- source name -> most items it may add to the menu, e.g. { lsp = 50 }.
  max_items = {},
  -- Wait this long after typing stops before the menu opens.
  delay_ms = 0,
  -- Match items fuzzily ('completeopt' "fuzzy").
  fuzzy = true,
  -- Show documentation for the selected item ('completeopt' "popup").
  docs = true,
  -- Widest an LSP item's name (abbr) and detail (menu) columns may be;
  -- longer text is cut with "…". One long item, like an auto-import path,
  -- would otherwise widen the whole menu, push the kind column off screen
  -- and leave the docs popup no room. 0 means no limit.
  max_width = { abbr = 40, menu = 30 },

  path = {
    -- Resolve relative paths against the buffer's directory ("buffer")
    -- or Neovim's working directory ("cwd").
    relative_to = "buffer",
    -- List dotfiles even when the typed name doesn't start with ".".
    hidden = true,
  },

  snippets = {
    -- Directories holding VSCode-style snippet files: <filetype>.json,
    -- plus all.json for snippets offered in every filetype.
    paths = { vim.fn.stdpath("config") .. "/snippets" },
    -- filetype -> other filetypes whose snippets it also gets,
    -- e.g. { typescriptreact = { "typescript", "javascript" } }.
    extends = {},
  },

  signature = {
    enabled = true,
    -- Characters that open signature help. nil asks each server for its
    -- own trigger characters.
    triggers = nil,
    -- Border of the signature window; nil follows 'winborder'.
    border = nil,
  },
}

M.options = vim.deepcopy(M.defaults)

---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.notify(msg, level)
  vim.notify("completion: " .. msg, level or vim.log.levels.INFO)
end

return M
