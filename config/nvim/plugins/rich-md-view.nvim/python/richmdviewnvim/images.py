"""Inline images through kitty Unicode placeholders.

A block made only of local images (`![alt](path)`, one per line) is drawn
as placeholder cells: U+10EEEE with the image id in the 24-bit foreground
color and a row diacritic. The PNG itself goes to Neovim over the socket,
which uploads it to the host terminal; kitty then draws the image over
those cells. They are ordinary text to everything else, so scrolling and
caching treat an image like any other rendered lines.
"""

import io
import math
import os
import re
import stat
import urllib.parse
import warnings
from collections.abc import Callable

from PIL import Image

# Huge images are skipped like unreadable ones, instead of printing a
# warning over the preview.
warnings.simplefilter("error", Image.DecompressionBombWarning)

PLACEHOLDER = "\U0010eeee"
# The first 60 row/column diacritics from kitty's rowcolumn-diacritics.txt.
# fmt: off
DIACRITICS = (
    "\u0305\u030d\u030e\u0310\u0312\u033d\u033e\u033f\u0346\u034a"
    "\u034b\u034c\u0350\u0351\u0352\u0357\u035b\u0363\u0364\u0365"
    "\u0366\u0367\u0368\u0369\u036a\u036b\u036c\u036d\u036e\u036f"
    "\u0483\u0484\u0485\u0486\u0487\u0592\u0593\u0594\u0595\u0597"
    "\u0598\u0599\u059c\u059d\u059e\u059f\u05a0\u05a1\u05a8\u05a9"
    "\u05ab\u05ac\u05af\u05c4\u0610\u0611\u0612\u0613\u0614\u0615"
)
# fmt: on
MAX_ROWS = 30
# Assumed cell size in pixels; only the 1:2 ratio matters for the box, and
# kitty keeps the aspect ratio inside it anyway.
CELL_W, CELL_H = 10, 20
# High byte of the image ids is NAMESPACE plus the PID mod 64, so viewers
# in one terminal mostly don't share ids; iron.nvim uses 128-255.
NAMESPACE = 64

IMAGE_LINE = re.compile(
    r'^\s*!\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)\s*$'
)


def image_paths(src: str, base: str) -> list[str] | None:
    """The local files an image-only block shows, else None.

    Relative paths resolve against the directory base.
    """
    paths = []
    for line in src.split("\n"):
        match = IMAGE_LINE.match(line)
        if not match or "://" in match.group(1):
            return None
        ref = os.path.expanduser(urllib.parse.unquote(match.group(1)))
        paths.append(os.path.join(base, ref))
    return paths


def mtime(path: str) -> int | None:
    try:
        return os.stat(path).st_mtime_ns
    except OSError:
        return None


class Images:
    def __init__(
        self,
        send: Callable[[int, int, int, bytes], None],
        free: Callable[[int], None],
    ) -> None:
        # send(id, cols, rows, png) hands an image to Neovim to upload;
        # free(id) has it delete one.
        self.send = send
        self.free = free
        # path -> ((mtime, cols, rows), id) of its latest upload
        self.ids: dict[str, tuple[tuple[int, int, int], int]] = {}
        self.id_base = (NAMESPACE + os.getpid() % 64) << 16
        self.serial = 0

    def stamp(self, src: str, base: str) -> tuple[int | None, ...]:
        """Modification times of the files an image-only block shows, so
        the block is drawn again when one changes."""
        return tuple(map(mtime, image_paths(src, base) or []))

    def render(self, src: str, width: int, base: str) -> list[str] | None:
        """Placeholder rows for an image-only block, else None."""
        paths = image_paths(src, base)
        if paths is None:
            return None
        rows = []
        for path in paths:
            block = self._image(path, width)
            if block is None:
                return None
            if rows:
                rows.append("")
            rows.extend(block)
        return rows

    def _image(self, path: str, width: int) -> list[str] | None:
        try:
            st = os.stat(path)
            # Anything else (a FIFO, /dev/stdin) could block forever.
            if not stat.S_ISREG(st.st_mode):
                return None
            with Image.open(path) as im:
                cols, rows = self._box(im.size, width)
                key = (st.st_mtime_ns, cols, rows)
                old_key, image_id = self.ids.get(path, (None, 0))
                if key != old_key:
                    if old_key:
                        # Resized or changed: never shown again.
                        self.free(image_id)
                    image_id = self._upload(im, cols, rows)
                    self.ids[path] = key, image_id
        except Exception:
            # Missing or unreadable: rich shows the alt text instead.
            return None
        return placeholders(image_id, cols, rows, (width - cols) // 2)

    def _box(self, size: tuple[int, int], width: int) -> tuple[int, int]:
        w, h = size
        cols = max(1, min(width - 2, math.ceil(w / CELL_W)))
        rows = math.ceil(cols * CELL_W * h / w / CELL_H)
        if rows > MAX_ROWS:
            rows = MAX_ROWS
            cols = max(1, round(rows * CELL_H * w / h / CELL_W))
        return cols, max(1, rows)

    def _upload(self, im: Image.Image, cols: int, rows: int) -> int:
        # Twice the assumed cell size stays sharp on HiDPI screens without
        # sending a full-size photo through the socket.
        im.thumbnail((cols * CELL_W * 2, rows * CELL_H * 2))
        if im.mode not in ("RGB", "RGBA", "L", "LA"):
            im = im.convert("RGBA")
        out = io.BytesIO()
        im.save(out, "PNG")
        self.serial = self.serial % 65535 + 1
        image_id = self.id_base + self.serial
        self.send(image_id, cols, rows, out.getvalue())
        return image_id


def placeholders(
    image_id: int, cols: int, rows: int, indent: int
) -> list[str]:
    red, green, blue = image_id >> 16, (image_id >> 8) & 255, image_id & 255
    color = f"\x1b[38;2;{red};{green};{blue}m"
    # Later cells in a row inherit row and column from their left neighbor.
    return [
        " " * indent
        + color
        + PLACEHOLDER
        + DIACRITICS[row]
        + DIACRITICS[0]
        + PLACEHOLDER * (cols - 1)
        + "\x1b[39m"
        for row in range(rows)
    ]
