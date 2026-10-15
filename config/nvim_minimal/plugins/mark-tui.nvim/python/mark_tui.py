"""Live markdown viewer driven by Neovim over a Unix socket.

Neovim sends two kinds of messages:

  T <cursor> <nbytes>\n<bytes>   new buffer text (cursor is 1-based)
  C <cursor>\n                   cursor moved, text unchanged

The document is split into top-level markdown blocks. Each block is rendered
with rich on its own and cached by its source text, so a keystroke only
re-renders the block being edited. Cursor moves only re-slice cached lines.
"""

import os
import re
import selectors
import signal
import socket
import sys

from rich.console import Console
from rich.theme import Theme

try:
    from mark_math import MathMarkdown as Markdown, parser
except ImportError:
    # Without mdit-py-plugins/pylatexenc, math is shown as raw source.
    from markdown_it import MarkdownIt
    from rich.markdown import Markdown

    # Same parser config as rich.markdown, so block boundaries agree.
    parser = MarkdownIt().enable("strikethrough").enable("table")

console = Console(
    force_terminal=True, theme=Theme({"markdown.latex": "italic magenta"})
)

ANSI = re.compile(r"\x1b\[[0-9;]*m")

cache = {}  # block source -> rendered lines
lines = []  # rendered document, one ANSI string per row
spans = []  # (src_start, src_end, out_start, out_len) per block
cursor = 1


def split_blocks(text):
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


def is_blank(line):
    return not ANSI.sub("", line).strip()


def render_block(src):
    rendered = cache.get(src)
    if rendered is None:
        with console.capture() as cap:
            console.print(Markdown(src))
        rendered = cap.get().rstrip("\n").split("\n")
        # rich pads some blocks (lists) with blank lines; render() adds its own.
        while len(rendered) > 1 and is_blank(rendered[0]):
            rendered.pop(0)
        while len(rendered) > 1 and is_blank(rendered[-1]):
            rendered.pop()
        cache[src] = rendered
    return rendered


def render(text):
    global lines, spans, cache
    old, cache = cache, {}
    new_lines, new_spans = [], []
    for start, end, src in split_blocks(text):
        if src in old:
            cache[src] = old[src]
        if new_lines:
            new_lines.append("")
        block = render_block(src)
        new_spans.append((start, end, len(new_lines), len(block)))
        new_lines.extend(block)
    lines, spans = new_lines, new_spans


def target_row():
    """Map the source cursor line to a row of rendered output."""
    cur = cursor - 1
    for start, end, out_start, out_len in reversed(spans):
        if cur >= start:
            frac = min((cur - start) / max(end - start, 1), 1.0)
            return out_start + int(frac * out_len)
    return 0


def draw():
    height = os.get_terminal_size().lines
    top = target_row() - height // 3
    top = max(0, min(top, len(lines) - height))
    rows = lines[top : top + height]
    sys.stdout.write("\x1b[H" + "\x1b[K\r\n".join(rows) + "\x1b[K\x1b[J")
    sys.stdout.flush()


def main():
    global cursor

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(sys.argv[1])

    # Wake the selector on resize so the redraw is immediate.
    wake_r, wake_w = socket.socketpair()
    wake_r.setblocking(False)
    wake_w.setblocking(False)
    signal.set_wakeup_fd(wake_w.fileno())
    signal.signal(signal.SIGWINCH, lambda *_: None)

    sel = selectors.DefaultSelector()
    sel.register(sock, selectors.EVENT_READ)
    sel.register(wake_r, selectors.EVENT_READ)

    sys.stdout.write("\x1b[?1049h\x1b[?25l")
    buf = b""
    text = ""
    try:
        while True:
            dirty = False
            for key, _ in sel.select():
                if key.fileobj is wake_r:
                    wake_r.recv(4096)
                    console.size = os.get_terminal_size()
                    cache.clear()
                    render(text)
                    dirty = True
                    continue
                chunk = sock.recv(1 << 16)
                if not chunk:
                    return
                buf += chunk

            # Apply every complete message; only the latest text matters.
            new_text = None
            while b"\n" in buf:
                header, rest = buf.split(b"\n", 1)
                parts = header.split()
                if parts[0] == b"T":
                    n = int(parts[2])
                    if len(rest) < n:
                        break
                    new_text = rest[:n].decode("utf-8", "replace")
                    rest = rest[n:]
                cursor = int(parts[1])
                buf = rest
                dirty = True

            if new_text is not None and new_text != text:
                text = new_text
                render(text)
            if dirty:
                draw()
    finally:
        sys.stdout.write("\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
