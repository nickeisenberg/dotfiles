# hunks.nvim

Signs for the lines you have added, changed or removed since the file was
staged, updated as you type, and actions on those hunks: jump, preview,
stage, reset, diff the file, blame a line. A small stand-in for gitsigns.

## Setup

```lua
require("hunks").setup({
  signs = { add = "┃", change = "┃", delete = "▁", topdelete = "▔", changedelete = "~" },
  priority = 6, -- sign priority; diagnostics use 10
  base = "index", -- or a revision, e.g. "HEAD"
  debounce = 100, -- ms between an edit and the signs updating
})
```

## Actions

| Lua | `:Hunks` | Does |
|---|---|---|
| `next(count?)`, `prev(count?)` | `next [N]`, `prev [N]` | jump `N` (or `[count]`) hunks, wrapping with `'wrapscan'` |
| `preview()` | `preview` | the hunk under the cursor in a float |
| `stage(range?)` | `[range]stage` | stage the hunk, or just the lines in `range` |
| `reset(range?)` | `[range]reset` | put the base's lines back; `u` undoes it |
| `undo_stage()` | `undo_stage` | put back the index entry from before the last stage |
| `diffthis()` | `diffthis` | the base in a split, in diff mode with the buffer |
| `blame()` | `blame` | the line's commit and message in a float |
| `toggle()` | `toggle` | signs on or off |
| `refresh()` | `refresh` | fetch the base again |
| `base(rev?)` | `base [rev]` | compare against `rev` from now on; without one, show it |

`range` is `{ line1, line2 }` in either order, such as
`{ vim.fn.line("."), vim.fn.line("v") }` from visual mode.

Highlights: `HunksAdd`, `HunksChange`, `HunksDelete` (linked to `Added`,
`Changed`, `Removed`), `HunksTopDelete`, `HunksChangeDelete`.

## How it works

- **The base** is read with `git show :./<file>` in the background, and
  again only when `.git/index`, `HEAD` or `logs/HEAD` changes (checked on
  `BufEnter`, `FocusGained`, `CursorHold` and fugitive's `FugitiveChanged`),
  so a `git add` or commit from anywhere shows up. Every action checks
  this first too. Untracked files get no signs.
- **Hunks** come from `vim.text.diff` between the base and the buffer,
  recomputed after edits (watched with `nvim_buf_attach`, so edits
  from formatters and LSP count too) at most every `debounce` ms.
- **Staging** writes no patch: the base with the chosen hunks applied is
  stored with `git hash-object -w`, and the file's index entry is pointed at
  it with `git update-index --cacheinfo`. The buffer needn't be saved.
  Before writing, the index entry is checked against the base the hunks
  came from; if it moved on, nothing is staged and the signs refresh.
  Undo points the entry back, unless the index changed since.
- **Blame** feeds the buffer to `git blame --contents -`, so unsaved
  changes show as not committed yet.

## Files

| File | Job |
|---|---|
| `lua/hunks/init.lua` | `setup()`, the autocmds, `:Hunks` |
| `lua/hunks/config.lua` | defaults and options |
| `lua/hunks/buffer.lua` | per-buffer base and hunks |
| `lua/hunks/diff.lua` | computing, cutting and applying hunks |
| `lua/hunks/signs.lua` | signs and highlights |
| `lua/hunks/actions.lua` | nav, preview, reset, stage, diffthis, blame |
| `lua/hunks/git.lua` | repository root, change stamp, running git |
