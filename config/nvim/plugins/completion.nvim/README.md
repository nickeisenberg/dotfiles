# completion.nvim

Completion as you type, built on Neovim's own `'autocomplete'` (0.12+).
LSP items, buffer words, file paths and your own snippets show up in one
menu; signature help opens as you type a call.

## Setup

```lua
require("completion").setup({
  sources = { "path", "snippets", "lsp", "buffer" }, -- priority order
  max_items = { lsp = 50 }, -- per-source cap, optional
  delay_ms = 0, -- wait after typing before the menu opens
  fuzzy = true, -- 'completeopt' "fuzzy"
  docs = true, -- 'completeopt' "popup": docs for the selected item
  path = { relative_to = "buffer", hidden = true },
  snippets = {
    paths = { vim.fn.stdpath("config") .. "/snippets" },
    extends = { typescriptreact = { "typescript", "javascript" } },
  },
  signature = { enabled = true, triggers = nil, border = "rounded" },
})
```

Every option is optional; the values above are the defaults, except
`max_items`, `extends` and `border`.

Keys are Neovim's: `<C-n>`/`<C-p>` move through the menu, `<C-y>` accepts,
`<C-e>` closes it. In a snippet, `<Tab>`/`<S-Tab>` jump between fields.

## How it works

Neovim does the heavy lifting. With `'autocomplete'` on, it asks every
source in `'complete'` as you type, merges their items into one menu, and
gives slow sources a decaying time budget so typing never waits on them.
`setup()` sets these options:

| Option | Value |
|---|---|
| `'autocomplete'` | on |
| `'autocompletedelay'` | `delay_ms` |
| `'complete'` | one or more flags per source, in `sources` order |
| `'completeopt'` | `menuone,noselect`, plus `fuzzy` and `popup` |

The sources:

- **lsp** is `o`, the omnifunc, which Neovim points at LSP completion when
  a server attaches. On `LspAttach` the plugin also calls
  `vim.lsp.completion.enable()`; that is what expands an accepted item's
  snippet, adds its imports and runs its command.
- **buffer** is `.,w,b`: words from this buffer, buffers in other windows
  and other loaded buffers.
- **path** and **snippets** are Lua functions in the `'completefunc'`
  shape (`F{func}` flags). Each one returns -3 when it has nothing to
  offer at the cursor, so it never blocks the others.

## Snippets

Snippet files use the VSCode format, one per filetype, plus `all.json`
for every filetype:

```json
{
  "main guard": {
    "prefix": "ifmain",
    "body": ["if __name__ == \"__main__\":", "\t${1:main()}"],
    "description": "Run only as a script"
  }
}
```

`body` uses LSP snippet syntax, which `vim.snippet.expand()` understands:
`$1`, `${1:default}`, `$0` for the final cursor position. A file is read
again when it changes, so edits show up without a restart.

## Files

| File | Job |
|---|---|
| `lua/completion/init.lua` | `setup()`: options, autocmds |
| `lua/completion/config.lua` | defaults, options and `notify` |
| `lua/completion/signature.lua` | signature help on trigger characters |
| `lua/completion/sources/path.lua` | the path source |
| `lua/completion/sources/snippets.lua` | snippet files, source and expansion |
