# rich-md-view.nvim

A live markdown preview for Neovim, rendered in a terminal split by
[rich](https://github.com/Textualize/rich).

Edit markdown on the left and the rendered version follows on the right:
it re-renders as you type, tracks your cursor, and scrolling the preview
scrolls the source back.

- **Live:** only the block you're editing is re-rendered, so it keeps up
  with typing in large files.
- **Synced scrolling, both ways:** the preview keeps your cursor a third of
  the way down; scroll the preview and the source window follows.
- **Math:** `$inline$`, `$$display$$` and `\begin{align}` are converted to
  Unicode (`x^2 + y_1` → `x² + y₁`, `\alpha \leq \beta` → `α ≤ β`,
  `\frac{a+b}{c}` → `(a+b)/c`), with aligned columns at `&`.
- **Inline images** in kitty and ghostty, drawn at full resolution with
  the kitty graphics protocol. Elsewhere, an image is a short `📷 alt text`.
- **Distinct headings:** `#` is a full-width band, `##` is underlined by
  a rule, `###` and `####` get a marker, so levels read at a glance.
- Tables, lists, task lists, block quotes, code blocks with syntax
  highlighting, links, and everything else rich's markdown renderer
  supports.

## Requirements

- Neovim 0.11+
- Python 3.10+ with the packages in `pyproject.toml`: rich, markdown-it-py,
  mdit-py-plugins, pylatexenc and Pillow
- For images: kitty or ghostty, and `termguicolors` on

## Installation

Install the plugin with your plugin manager, then install its Python
dependencies. The simplest way is the plugin's own venv, under
`stdpath("data")/rich-md-view/venv`, which it uses automatically:

```vim
:lua require("rich-md-view.build").run()
```

That creates the venv with `python3.12` or `python3` (`py -3` on Windows)
and pip installs the plugin into it. Run it as a build step so updates
reinstall the dependencies. With lazy.nvim:

```lua
{
  dir = "~/path/to/rich-md-view.nvim",
  ft = "markdown",
  build = function()
    require("rich-md-view.build").run()
  end,
  opts = {},
}
```

With pack.nvim, pass the build's `plugin` so it runs asynchronously:

```lua
build = function(plugin)
  require("rich-md-view.build").run(plugin)
end,
```

`run()` takes options as its second argument:

```lua
require("rich-md-view.build").run(plugin, {
  -- Interpreter to make the venv with: a path, or an argv list such as
  -- { "py", "-3.13" }. Changing it makes the venv again on the next build.
  python = "/usr/bin/python3.13",
  -- Where to make the venv.
  venv = "~/.venvs/rich-md-view",
})
```

With a custom `venv`, give `setup()` the same path so the viewer runs from
it:

```lua
local venv = "~/.venvs/rich-md-view"

build = function(plugin)
  require("rich-md-view.build").run(plugin, { venv = venv })
end,
config = function()
  require("rich-md-view").setup({ venv = venv })
end,
```

To use an interpreter of your own instead, install into it and set
`python`:

```sh
/path/to/python -m pip install /path/to/rich-md-view.nvim
```

```lua
require("rich-md-view").setup({
  python = vim.fn.expand("~/.venvs/nvim/bin/python"),
})
```

Either way the plugin runs the copy of `richmdviewnvim` in its own `python/`
directory; the install is for the dependencies.

## Usage

Open a markdown file and run `:RichMdViewOpen`. The preview opens in a split
on the right and follows whichever markdown buffer you're in. Close it with
`:RichMdViewClose` or `q` in the preview.

### Commands

| Command            | Description                            |
| ------------------ | -------------------------------------- |
| `:RichMdViewOpen`  | Open the preview in a right split      |
| `:RichMdViewClose` | Close the preview                      |

### Keys in the preview

| Keys                              | Action                    |
| --------------------------------- | ------------------------- |
| `j` / `k`, `<Down>` / `<Up>`      | Scroll one line           |
| `<C-e>` / `<C-y>`                 | Scroll one line           |
| `<ScrollWheelDown>` / `<ScrollWheelUp>` | Scroll three lines  |
| `<C-d>` / `<C-u>`                 | Scroll half a page        |
| `<C-f>` / `<C-b>`                 | Scroll a page             |
| `gg` / `G`                        | Top / bottom              |
| `q`                               | Close the preview         |

Line and page scrolls take a count, as in Vim. Scrolling pins the preview
where you put it until the cursor moves in the source again.

### Lua API

```lua
local view = require("rich-md-view")

view.open()
view.close()
view.scroll(5)        -- rows; negative scrolls up
view.scroll("top")    -- or "bottom"
```

For example, a mapping to open it:

```lua
vim.keymap.set("n", "<leader>mp", require("rich-md-view").open, {
  desc = "Markdown preview",
})
```

## Configuration

These are the defaults:

```lua
require("rich-md-view").setup({
  -- Interpreter that runs the viewer (`python -m richmdviewnvim`). nil
  -- means the one in `venv` if it exists, else `python3` from $PATH.
  python = nil,
  -- The venv `build.run()` made; set it if you gave `run()` a `venv`.
  -- nil means the default, stdpath("data")/rich-md-view/venv.
  venv = nil,
  -- Wait this long after a change or cursor move before updating, so a
  -- burst of typing renders once.
  debounce_ms = 30,
  -- Draw local images inline in kitty and ghostty. false always shows
  -- the alt text instead.
  images = true,
})
```

Colors and heading styles are rich styles in `THEME`, in
`python/richmdviewnvim/markdown.py`.

## Images

Images are drawn when all of these hold:

- the terminal is kitty or ghostty
- `termguicolors` is on (the plugin warns if it's off)
- `images` isn't `false`
- the image is a local file, alone on its line(s): `![alt](path)`

Paths are relative to the markdown file. Any format Pillow reads works; the
image is converted to PNG and scaled down to fit the preview width, up to
30 rows tall. Images in the middle of a sentence, remote URLs and missing files show
as `📷 alt text`, as does every image in other terminals.

**tmux** needs passthrough for the graphics commands to reach the terminal:

```tmux
set -g allow-passthrough on
```

**Detection.** The terminal is identified from `TERM` first, since every
terminal sets that itself. Kitty's and ghostty's own variables
(`KITTY_WINDOW_ID`, `GHOSTTY_RESOURCES_DIR`, `TERM_PROGRAM=ghostty`) are only
trusted when no other terminal's variables are set, because they're
inherited by anything started from kitty or ghostty, such as Alacritty
launched from a ghostty shell. If images are wrongly enabled or disabled
in your setup, set `images` explicitly.

## How it works

`:RichMdViewOpen` opens a terminal split running `python -m richmdviewnvim`,
which connects back to Neovim over a Unix socket. Neovim sends the buffer
text, cursor moves and preview scrolls; the viewer replies with the source
lines to scroll to and with images to upload. Every message has the same
frame:

```
<kind> <args...> <nbytes>\n<payload>
```

The protocol is documented in `python/richmdviewnvim/protocol.py`, with the
Neovim side in `lua/rich-md-view/protocol.lua`.

The viewer splits the document into top-level markdown blocks and renders
each with rich on its own, cached by its source text, so a keystroke
re-renders one block and a cursor move re-renders nothing. Images use kitty
Unicode placeholders: the viewer prints placeholder cells as ordinary text,
and Neovim uploads the PNG to the outer terminal, which draws it over them.

```
lua/rich-md-view/
  init.lua       setup, commands, window, socket, scroll sync
  protocol.lua   message encoding/decoding
  images.lua     uploaded image ids, terminal detection
  kitty.lua      kitty graphics protocol
python/richmdviewnvim/
  viewer.py      main loop and Viewport (what's on screen)
  document.py    Document: blocks, cache, source ↔ row mapping
  markdown.py    rich Markdown subclass: math, headings, image text, THEME
  latex.py       LaTeX → Unicode
  images.py      image loading and placeholder cells
  protocol.py    the socket protocol
```

## Demo

`demo/demo.md` exercises everything above: headings, lists, a table, code,
math, and a PNG, a JPEG and a missing image. Open it and run
`:RichMdViewOpen`.

## Development

```sh
ruff check python && ruff format --check python
pyright
```

Both read their settings from `pyproject.toml`.
