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
  max_width = { abbr = 40, menu = 30 }, -- cut long LSP names/details with …
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

Each directory in `snippets.paths` is laid out one of two ways:

- **Plain**: `<filetype>.json`, plus `all.json` for every filetype.
- **A VSCode snippet extension**, such as
  [friendly-snippets](https://github.com/rafamadriz/friendly-snippets):
  a `package.json` whose `contributes.snippets` maps languages to files.

A `package.json` in the directory selects the second. The snippet files
are the same either way, in the VSCode format:

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

With `docs` on, selecting a snippet in the menu previews it: its
description, then the text it expands to with every field at its default,
highlighted in the buffer's language.

Neovim's parser has two gaps worth knowing about when writing or
borrowing snippets:

- **Tabstops inside a placeholder** (`${3:yield $4}`) are valid LSP
  syntax but don't parse. Such a body is retried with the inner tabstops
  dropped (`${3:yield }`), so it still expands, minus those stops.
- **TextMate-only features** — regex transforms like `${1/(a)/b/}` —
  aren't supported at all. Accepting such a snippet warns and leaves the
  typed prefix in place. In friendly-snippets this is 13 of the ~570
  snippets for Python, Lua, shell, LaTeX, Markdown, gitcommit, C++ and
  JSON, all of them LaTeX.

## Files

| File | Job |
|---|---|
| `lua/completion/init.lua` | `setup()`: options, autocmds |
| `lua/completion/config.lua` | defaults, options and `notify` |
| `lua/completion/signature.lua` | signature help on trigger characters |
| `lua/completion/sources/path.lua` | the path source |
| `lua/completion/sources/snippets.lua` | snippet files, source and expansion |
