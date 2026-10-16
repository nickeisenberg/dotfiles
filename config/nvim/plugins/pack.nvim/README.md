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

A file can also return a list, `{ "owner/a", "owner/b" }` or
`{ { "owner/a", config = ... }, { "owner/b" } }`. A list can't carry options
of its own: `{ "owner/a", "owner/b", config = f }` is an error.

### Notes

- **`enabled = false` wins.** A disabled plugin stays out even when another
  spec lists it in `deps`; you get a warning naming the dependent.
- **`deps` are merged.** A plugin listed both as a dependency and on its own
  is one plugin; options missing from one spec are filled in from the other.
- **`config` runs before `plugin/` files.** During startup vim.pack adds
  plugins with `:packadd!`, and local plugins are only put on
  'runtimepath', so their `plugin/` scripts are sourced later, at the usual
  point in startup. `require("x").setup()` works; calling a command that a
  Vimscript plugin defines in `plugin/` does not.
- **Builds** run after install and update. Local plugins never install or
  update, so their builds only run through `:PackBuild`. Builds don't hold
  up `config`, so on the very first install a plugin may start before its
  build is done.
- **Local plugins** get their directory and its `after/` directory added to
  'runtimepath'.

## Builds

`build` takes three forms:

- **A shell command**, `build = "make"`. Runs through 'shell' and
  'shellcmdflag' in the plugin root, in the background. On failure its
  stdout and stderr are shown.
- **An Ex command**, `build = ":TSUpdate"`. Runs after the plugin is loaded.
- **A function**, `build = function(plugin) ... end`. Runs after the plugin
  is loaded, with `plugin.spec`, `plugin.path` (the plugin root) and
  `plugin.run`.

`plugin.run(cmd, opts?)` runs `cmd`, a list like `{ "make", "install" }`
with no shell in between, and returns its `vim.SystemCompleted`. It waits
without blocking Neovim: the build pauses until the command exits, and the
editor keeps running. A non-zero exit raises an error, which stops the build
and reports the command's output. `opts` go to `vim.system()`; `cwd`
defaults to the plugin root.

Because nothing goes through a shell, a function build is the way to write
one build that works on Unix and Windows:

```lua
build = function(plugin)
  local win = vim.fn.has("win32") == 1
  plugin.run({ win and "py" or "python3", "-m", "venv", "venv" })
  local python = win and "venv/Scripts/python.exe" or "venv/bin/python"
  plugin.run({ python, "-m", "pip", "install", "." })
end
```

Only `plugin.run` waits without blocking; calling `vim.system():wait()`
yourself still freezes the editor.

## Commands

- `:PackUpdate[!] [names...]` updates plugins. Without `!` it opens
  vim.pack's confirmation buffer, with each revision's commit message added.
- `:PackStatus` shows installed plugins without fetching.
- `:PackBuild [names...]` runs builds again: the named plugins', or every
  plugin that has one.
- `:PackClean[!]` deletes installed plugins that are in no spec and not
  loaded. Without `!` it asks first.
