# files.nvim

Directories as buffers you edit to change the file system, like oil.nvim.
The design (a hidden number on each line) comes from
[mini.files](https://github.com/echasnovski/mini.files) (MIT).

```
../
sub/
A.txt
b.txt
```

| Do | To |
|---|---|
| edit a name (`ciw`, `C`, ...) | rename |
| add a line (end it with `/` for a directory; `a/b/c.txt` works) | create |
| `dd` | delete |
| `dd` here, `p` in another directory | move |
| `yy` here, `p` elsewhere | copy |
| `:w` | list the changes, ask, then do them |
| `:e!` | drop the changes |

`:w` in any directory buffer saves the changes in all of them at once,
which is what makes a move across directories work. Save after pasting,
not between: saving after just the `dd` deletes the file.

Deleted entries go to `stdpath("data")/files.nvim/trash` (with a number
added to the name), unless `trash = false`. `:FilesTrash` opens it as a
directory buffer: move an entry out to restore it, delete one there to
delete it for good. Nothing is ever overwritten:
a change whose target exists, two entries with the same name, or a
rename onto a path that is itself being renamed is refused, and nothing
happens.

## Setup

```lua
require("files").setup({
  show_hidden = true,
  trash = true,
  git = true, -- `git status --short` letters in the sign column
  keymaps = { -- buffer-local; a table given replaces these, false drops one
    ["<CR>"] = "select", -- open the file or directory under the cursor
    ["-"] = "parent",
    ["_"] = "cwd",
    ["g."] = "toggle_hidden",
    ["<C-l>"] = "refresh",
    ["<C-p>"] = "preview", -- toggle a split showing the entry under the cursor
    ["<C-s>"] = "select_vsplit",
    ["<C-h>"] = "select_split",
    ["<C-t>"] = "select_tab",
    ["<C-c>"] = "close", -- back to the buffer you opened it from
  },
})
```

`:Files [dir]` opens a directory, by default the current file's with the
cursor on it; in a directory buffer, its parent, like `-` and the `../`
line (which is never saved as a change). `nvim .` and `:e somedir` open one too (netrw is turned off).

Highlights: `FilesDirectory`, `FilesGitStaged`, `FilesGitUnstaged`,
`FilesGitUntracked`, `FilesGitConflict`.

## How it works

- **Lines** are `/12 name`, the number hidden with `conceal` and the cursor
  kept off it. Numbers are given out per path for the whole session, so
  a yanked line still names its file in another buffer.
- **Saving** reads every modified directory buffer: a number gone from its
  buffer is a delete; a line without one is a create; a number under a new
  name is a rename, or a move in another directory, and a copy if the
  original line is still there. Moves and renames run first, so a file
  moved out of a directory that is deleted in the same save survives.
- **Open buffers** of a renamed file, or of files in a renamed directory,
  follow it. One with unsaved changes needs `:w!` afterwards.
- **Git status** comes from `git status --porcelain` for the directory,
  run in the background whenever it is shown; a directory shows the first
  status inside it.
- A buffer you come back to without changes is read from disk again.
- **Preview** (`<C-p>`) splits the window (to the right, or below when it
  is narrower than 80 columns) and follows the cursor. It shows the real
  thing: a file's own buffer, a directory's own directory buffer. Go into
  it to edit the file, or to browse from that directory (with its own
  `<C-p>`); the window you came from keeps its preview, which still
  follows its cursor. A buffer loaded only for the preview is wiped when
  it moves on, unless you went into it or changed it; buffers you already
  had open are left alone. Opening a file loads it as usual (filetype,
  LSP); a binary file just says so. The preview closes when you open a
  file in its window, or with `<C-p>` again.

`cc` replaces the whole line, number and all, so it is a delete and a
create (the confirmation shows it). To rename, change the name: `ciw`,
`C`, or `cw`.

## Files

| File | Job |
|---|---|
| `lua/files/init.lua` | `setup()`, opening directories, keys, autocmds |
| `lua/files/config.lua` | defaults and options |
| `lua/files/view.lua` | directory buffers: render, parse lines, hidden numbers |
| `lua/files/index.lua` | the number for each path |
| `lua/files/sync.lua` | saving: changes, plan, confirm, apply |
| `lua/files/fs.lua` | reading directories, create/copy/move/delete |
| `lua/files/preview.lua` | the preview split |
| `lua/files/git.lua` | git status signs |
| `syntax/files.vim` | hides the numbers |
