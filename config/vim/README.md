# vim

The nvim config, rebuilt for Vim 9.2 in vim9script; Vim 9.0 and 9.1 work
too, with fallbacks (see [Vim versions](#vim-versions)). The only third-party
plugin is [yegappan/lsp](https://github.com/yegappan/lsp); everything else
is in this directory. External tools: `git`, `rg`, the language servers and
the formatters.

## Install

```sh
ln -s ~/dotfiles/config/vim ~/.vim
vim   # the first start clones yegappan/lsp into ~/.local/share/vim/pack/
```

To try it without installing, use `vim -Nu ~/dotfiles/config/vim/vimrc`.
Keep the `-N`: without it Vim starts in compatible mode, and some keys get
lost.

## Layout

| Path | What |
|---|---|
| `vimrc` | options, keymaps, autocmds, colorscheme, the plugin list and every plugin's config |
| `autoload/pack.vim` | the plugin manager |
| `plugins/<name>/` | the local plugins: `plugin/` (small, read at startup) and `autoload/` (the code, loaded on first use) |
| `after/ftplugin/` | per-filetype indent settings |

Remote plugins are cloned into `~/.local/share/vim/pack/remote/opt/`
(`$XDG_DATA_HOME` if set, or `g:pack_dir`), outside this repository. Swap,
backup, undo, viminfo and netrw history files go to `~/.local/state/vim/`.

## Plugins

```vim
pack#Begin()
Pack 'yegappan/lsp'                   # GitHub shorthand, or a full git URL
Pack 'owner/repo', {branch: 'dev'}    # or {tag: 'v1.0'} or {commit: 'abc123'}
Pack 'owner/repo', {build: 'make'}    # shell command, ':VimCmd' or a Funcref
Pack 'owner/repo', {as: 'other-name'} # folder name to install under
Pack 'owner/repo', {enabled: false}   # keep it on disk but don't load it
Pack 'picker'                         # local: vim/plugins/picker
Pack '~/code/my-plugin'               # local: any path
pack#End()
```

`pack#End()` clones missing plugins and loads the rest, so the config below
it can use their commands right away.

- `:PackUpdate` fetches every plugin, lists the new commits and asks before
  applying them. Builds run again for plugins that changed.
- `:PackClean` deletes plugin folders that aren't in the list (after
  asking).
- `:PackStatus` shows each plugin's branch or pin, commit, and any local
  changes.
- `:PackBuild [name]` runs build steps again.

A build that is a Funcref has to be a global function (`function('g:F')`),
because `Pack` arguments are evaluated inside pack.vim.

## Local plugins

| Plugin | Ported from | Notes |
|---|---|---|
| `statusline` | statusline.nvim | No gitsigns: the branch comes from `.git/HEAD`, and the +/~/- counts from diffing the buffer against the git index as you type. |
| `format` | format.nvim | `g:format_formatters`; an argument that is exactly `%` becomes the file name. Falls back to `:LspFormat`. |
| `completion` | completion.nvim | Two engines, picked by `g:completion_engine` (`'auto'`): **builtin** is Vim's `'autocomplete'` with path, LSP and buffer sources; **lsp** is yegappan/lsp's own completion plus buffer words, for Vims without `'autocomplete'`. Snippets are left out for now. Signature help comes from yegappan/lsp. |
| `float-term` | float-term.nvim | Terminals in a popup. From the terminal, `<C-\><C-n>` goes to Normal mode, where `<leader>t…` works. |
| `picker` | picker.nvim | `rg` for files and grep; `<leader>gd`/`<leader>gr` ask the language server through yegappan/lsp's documented server API (`:help lsp-custom-requests`). Also takes `<C-w>`/`<C-u>` in the prompt. |

The options for each plugin are listed at the top of its
`plugin/<name>.vim`.

## Vim versions

| Vim | What you get |
|---|---|
| 9.2, and 9.1.1590+ | everything |
| 9.1.0071 to 9.1.1589 | completion uses the lsp engine: no path completion as you type (`<C-x><C-f>` still works), and the menu shows names and kinds with details in the docs popup |
| 9.0 to 9.1.0070 | as above, and without `diff()`: the statusline counts follow the saved file instead of the buffer, and formatting replaces every line instead of only the changed ones |
| older than 9.0 | one warning, nothing loaded |

Some bundled packages are missing from older 9.x builds: without `comment`
there is no `gc`, and without `habamax` the colorscheme is `desert`. Yank
highlighting has its own fallback.

## Differences from the nvim config

- Neovim defaults that Vim lacks are set in the vimrc: `Y`, `[q`/`]q`,
  `[b`/`]b`, `[<Space>`/`]<Space>`, `gc` (the bundled comment package),
  `[d`/`]d` for diagnostics, and the cursor shape in insert mode.
- The WSL clipboard setup isn't ported yet.
- rich-md-view is not ported.
