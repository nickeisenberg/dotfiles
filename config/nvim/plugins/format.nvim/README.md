# format.nvim

Format buffers on save with a pipeline of external tools, falling back to
an attached language server's formatter.

## Setup

```lua
require("format").setup({
  formatters = {
    lua = {
      { command = "stylua", args = { "-" } },
    },
    python = {
      {
        command = "ruff",
        args = function(bufname)
          return { "format", "--stdin-filename", bufname, "-" }
        end,
      },
    },
  },
  format_on_save = true, -- BufWritePre autocmd
  timeout_ms = 5000, -- per step, and for the LSP request
})
```

`:Format` formats the current buffer; `require("format").format(bufnr)`
does the same from Lua.

## How it works

- **Pipelines.** `formatters[filetype]` is a list of steps run in order. The
  buffer goes to the first step on stdin, and each step's stdout is the next
  step's stdin. `args` is a list, or a function of the buffer's name for
  tools that need `--stdin-filename`.
- **All or nothing.** Every command is checked before any runs. If one is
  missing, fails or times out, the buffer is left as it was and the problem
  is reported. A missing command is reported once per session.
- **LSP fallback.** A filetype without a pipeline is formatted by an
  attached client that supports `textDocument/formatting`, if there is one.
- **Minimal edits.** The output is diffed against the buffer and only
  changed lines are replaced, so marks, folds, diagnostics and git signs on
  untouched lines stay put.
- **Skipped buffers.** Special (`buftype` set) and non-modifiable buffers
  are never formatted.

## Files

| File | Job |
|---|---|
| `lua/format/init.lua` | `setup()`, `format()`, the autocmd and `:Format` |
| `lua/format/config.lua` | defaults, options and `notify` |
| `lua/format/pipeline.lua` | runs the external steps |
| `lua/format/apply.lua` | writes the result back as a line diff |
| `lua/format/lsp.lua` | the LSP fallback |
