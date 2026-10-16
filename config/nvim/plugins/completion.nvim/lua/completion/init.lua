-- Completion as you type, built on Neovim's own 'autocomplete'.
--
-- Neovim collects items from every source in 'complete', merges them into
-- one menu and keeps slow sources from holding up typing. This plugin
-- picks the sources, adds path and snippet sources of its own, wires up
-- LSP completion and opens signature help.

local config = require("completion.config")
local signature = require("completion.signature")
local snippets = require("completion.sources.snippets")

local M = {}

-- source name -> its 'complete' flags. "o" is the omnifunc, which Neovim
-- points at LSP completion when a server attaches.
local FLAGS = {
  path = { "Fv:lua.require'completion.sources.path'.complete" },
  snippets = { "Fv:lua.require'completion.sources.snippets'.complete" },
  lsp = { "o" },
  buffer = { ".", "w", "b" },
}

local function complete_option()
  local flags = {}
  for _, name in ipairs(config.options.sources) do
    local source = FLAGS[name]
    if not source then
      config.notify("unknown source: " .. name, vim.log.levels.WARN)
    else
      local max = config.options.max_items[name]
      for _, flag in ipairs(source) do
        flags[#flags + 1] = max and (flag .. "^" .. max) or flag
      end
    end
  end
  return table.concat(flags, ",")
end

local function completeopt()
  local opts = { "menuone", "noselect" }
  if config.options.fuzzy then
    opts[#opts + 1] = "fuzzy"
  end
  if config.options.docs then
    opts[#opts + 1] = "popup"
  end
  return table.concat(opts, ",")
end

-- vim.lsp.completion.enable() is what applies an LSP item's side effects
-- when it is accepted: expanding snippets, adding imports, running
-- commands. Its own autotrigger stays off; 'autocomplete' already asks
-- the server as you type, including after "." and other trigger chars.
local function on_lsp_attach(ev)
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  if client and client:supports_method("textDocument/completion") then
    vim.lsp.completion.enable(true, client.id, ev.buf, {
      autotrigger = false,
    })
  end
end

---@param opts? table see completion.config.defaults
function M.setup(opts)
  config.setup(opts)

  vim.o.autocomplete = true
  vim.o.autocompletedelay = config.options.delay_ms
  vim.o.complete = complete_option()
  vim.o.completeopt = completeopt()

  -- Clearing the group makes calling setup() again safe.
  local group = vim.api.nvim_create_augroup("completion", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Enable LSP completion",
    callback = on_lsp_attach,
  })

  if vim.list_contains(config.options.sources, "snippets") then
    vim.api.nvim_create_autocmd("CompleteDone", {
      group = group,
      desc = "Expand accepted snippets",
      callback = snippets.expand_on_accept,
    })
  end

  if config.options.signature.enabled then
    signature.setup(group)
  end
end

return M
