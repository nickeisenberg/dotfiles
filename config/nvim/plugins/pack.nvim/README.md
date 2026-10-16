# pack.nvim

A thin wrapper around Neovim's built-in `vim.pack` (Neovim 0.12+). It reads
plugin specs from one Lua module per plugin, installs them with `vim.pack`,
runs build steps, and calls each plugin's `config`.

## Setup

```lua
require("pack").setup({
  import = "plugins", -- Lua module directory scanned for spec files
  local_dir = vim.fn.stdpath("config") .. "/plugins", -- base for relative `dir`
  base_url = "https://github.com/", -- prefix for "owner/repo" shorthand
})
```

## Specs

Each file in `lua/<import>/` (except `init.lua`) returns one spec or a list
of specs:

```lua
return {
  "owner/repo",            -- or a git URL, `src = ...`, or a local path
  name = "repo",           -- optional, defaults to the repo name
  version = "main",        -- optional, passed through to vim.pack
  dir = "picker.nvim",     -- local plugin; relative to `local_dir`
  deps = { "owner/dep" },  -- specs added before this one
  build = "make",          -- shell cmd, ":VimCmd", or function(plugin)
  config = function() end, -- run after every plugin is added
  enabled = false,         -- skip this spec
}
```

## Commands

- `:PackUpdate[!] [names...]` updates plugins. Without `!` it opens
  vim.pack's confirmation buffer, with each revision's commit message added.
- `:PackStatus` shows installed plugins without fetching.
- `:PackClean[!]` deletes plugins that are no longer in any spec.
