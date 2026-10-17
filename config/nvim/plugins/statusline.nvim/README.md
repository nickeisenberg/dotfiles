# statusline.nvim

A statusline that fits the colorscheme and shows each window's own buffer.

```
 NORMAL  main  +3 ~1 src/app.py [+]          2  1 ty: Indexing 40% python 12:5
```

Left: mode, git branch, lines changed since staged, path relative to
the repository with `[+]` when modified and `[RO]` when read-only.
Right: diagnostics, language servers, filetype, line:column.

Inactive windows show only the path and its flags, in `StatusLineNC`.

## Setup

```lua
require("statusline").setup({
  show = {
    mode = true,
    git = true,
    diff = true, -- +added ~changed -removed
    diagnostics = true,
    lsp = true,
    filetype = true,
    position = true,
  },
  icons = { error = "E ", warn = "W ", info = "I ", hint = "H " },
})
```

The default icons are Nerd Font codicons; set plain ones like the above
for a terminal font without them.

## How it works

- **Per window.** `'statusline'` is `%!v:lua.require'statusline'.render()`.
  Neovim evaluates a `%!` expression in the context of the *current*
  window, so `render()` uses `g:statusline_winid` to draw each window from
  its own buffer.
- **Branch.** Read from the repository's `HEAD` file, re-read only when its
  modification time changes. A checkout from a shell or another plugin
  shows up without running git. Worktrees and submodules (a `.git` file) work, and
  a detached HEAD shows a short hash.
- **Changed lines.** The buffer is diffed against the staged copy of the
  file with `vim.text.diff`, recounted when the buffer changes. The staged
  copy comes from `git show :<file>`, run in the background and again only
  when `.git/index` changes, so staging from anywhere shows up. Untracked
  files show no counts.
- **LSP.** `LspProgress` events are kept per client until the work ends;
  while a server reports progress it is shown, otherwise the names of the
  attached servers. `vim.lsp.status()` isn't used, because it consumes the
  messages and only the first window drawn would see them.
- **Colors.** `StlMode` and `StlGit` are built from the colorscheme's
  `PmenuSel`, `Visual` and `Directory`, and rebuilt on `ColorScheme`.
  Changed-line counts use the built-in `Added`, `Changed` and `Removed`.
- **Redraws** come from diagnostics, LSP and edit events,
  batched to one redraw per event-loop tick.

## Files

| File | Job |
|---|---|
| `lua/statusline/init.lua` | `setup()`, `render()`, the autocmds |
| `lua/statusline/config.lua` | defaults and options |
| `lua/statusline/parts.lua` | each piece of the line |
| `lua/statusline/git.lua` | repository root, branch and changed lines |
| `lua/statusline/lsp.lua` | per-client LSP progress |
| `lua/statusline/highlights.lua` | colors from the colorscheme |
