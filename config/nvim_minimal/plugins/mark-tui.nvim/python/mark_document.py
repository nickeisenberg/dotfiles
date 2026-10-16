"""The rendered document and how its rows map back to source lines.

The text is split into top-level markdown blocks. Each block is rendered
with rich on its own and cached by its source text, so a keystroke only
re-renders the block being edited.
"""

import os
import re
from typing import TYPE_CHECKING, NamedTuple

from mark_markdown import TuiMarkdown, parser
from rich.console import Console

if TYPE_CHECKING:
    from mark_image import Images

ANSI = re.compile(r"\x1b\[[0-9;]*m")


class Span(NamedTuple):
    """Where one block sits in the source and in the rendered rows."""

    src_start: int
    src_end: int
    out_start: int
    out_len: int


def split_blocks(text: str) -> list[tuple[int, int, str]]:
    """(start, end, source) of each top-level block, 0-based lines."""
    src = text.split("\n")
    # Level-0 openers and leaf blocks (fence, hr, ...) carry line maps.
    starts = [
        tok.map[0]
        for tok in parser.parse(text)
        if tok.level == 0 and tok.nesting >= 0 and tok.map
    ]
    out = []
    # A block runs until the next one starts; some plugins (amsmath) report
    # an end line that is one short.
    for start, nxt in zip(starts, starts[1:] + [len(src)]):
        end = nxt
        while end > start + 1 and not src[end - 1].strip():
            end -= 1
        out.append((start, end, "\n".join(src[start:end])))
    return out


def is_blank(line: str) -> bool:
    return not ANSI.sub("", line).strip()


class Document:
    def __init__(self, console: Console, images: "Images | None") -> None:
        self.console = console
        self.images = images  # None when inline images are off
        self.text = ""
        self.base = os.getcwd()  # relative image paths resolve against this
        self.lines: list[str] = []  # one ANSI string per row
        self.spans: list[Span] = []
        self._cache: dict[str, list[str]] = {}  # block source -> rows

    def update(self, text: str, base: str) -> None:
        """Show new buffer text, from a file in the directory base."""
        if base != self.base:
            self.base = base
            # Relative image paths now point elsewhere.
            self._cache.clear()
        elif text == self.text:
            return
        self.text = text
        self._render()

    def resize(self) -> None:
        """Re-render every block at the console's current width."""
        self._cache.clear()
        self._render()

    def row_of(self, line: int) -> int:
        """Map a 1-based source line to a row of rendered output."""
        cur = line - 1
        for span in reversed(self.spans):
            if cur >= span.src_start:
                size = max(span.src_end - span.src_start, 1)
                frac = min((cur - span.src_start) / size, 1.0)
                return span.out_start + int(frac * span.out_len)
        return 0

    def line_of(self, row: int) -> int:
        """Map a row of rendered output to a 1-based source line."""
        for span in reversed(self.spans):
            if row >= span.out_start:
                frac = min((row - span.out_start) / max(span.out_len, 1), 1.0)
                size = span.src_end - span.src_start
                return span.src_start + int(frac * size) + 1
        return 1

    def _render(self) -> None:
        # Blocks that are gone drop out of the cache.
        old, self._cache = self._cache, {}
        lines: list[str] = []
        spans: list[Span] = []
        for start, end, src in split_blocks(self.text):
            if src in old:
                self._cache[src] = old[src]
            if lines:
                lines.append("")
            block = self._render_block(src)
            spans.append(Span(start, end, len(lines), len(block)))
            lines.extend(block)
        self.lines, self.spans = lines, spans

    def _render_block(self, src: str) -> list[str]:
        rendered = self._cache.get(src)
        if rendered is None and self.images:
            rendered = self.images.render(src, self.console.width, self.base)
        if rendered is None:
            with self.console.capture() as cap:
                self.console.print(TuiMarkdown(src))
            rendered = cap.get().rstrip("\n").split("\n")
            # rich pads some blocks (lists) with blank lines; _render adds
            # its own.
            while len(rendered) > 1 and is_blank(rendered[0]):
                rendered.pop(0)
            while len(rendered) > 1 and is_blank(rendered[-1]):
                rendered.pop()
        self._cache[src] = rendered
        return rendered
