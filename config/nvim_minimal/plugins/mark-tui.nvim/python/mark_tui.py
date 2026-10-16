"""Live markdown viewer driven by Neovim over a Unix socket.

Neovim sends four kinds of messages:

  D <nbytes>\n<bytes>            directory of the buffer, before each T
  T <cursor> <nbytes>\n<bytes>   new buffer text (cursor is 1-based)
  C <cursor>\n                   cursor moved, text unchanged
  S <rows|top|bottom>\n          scroll by rows, from the preview window

Text and cursor messages make the view follow the cursor again; scroll
messages pin it until the next one. After a scroll the viewer replies with

  L <topline> <cursorline>\n     source lines to show, so Neovim can match

using the same anchor as following: the cursor sits a third of the way down.
With --images, image-only blocks become kitty placeholders (mark_image) and
each new image is sent for Neovim to upload to the host terminal:

  I <id> <cols> <rows> <nbytes>\n<png bytes>

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
top = 0  # first visible row, as last drawn
pinned = None  # row set by scrolling; None follows the cursor
images = None  # mark_image.Images when inline images are on


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
    if rendered is None and images:
        rendered = images.render(src, console.width)
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


def source_line(row):
    """Map a row of rendered output to a 1-based source line."""
    for start, end, out_start, out_len in reversed(spans):
        if row >= out_start:
            frac = min((row - out_start) / max(out_len, 1), 1.0)
            return start + int(frac * (end - start)) + 1
    return 1


def clamp(row, height):
    return max(0, min(row, len(lines) - height))


def scroll(arg):
    global pinned
    height = os.get_terminal_size().lines
    if arg == b"top":
        row = 0
    elif arg == b"bottom":
        row = len(lines)
    else:
        row = (top if pinned is None else pinned) + int(arg)
    pinned = clamp(row, height)


def draw():
    global top, pinned
    height = os.get_terminal_size().lines
    if pinned is None:
        top = clamp(target_row() - height // 3, height)
    else:
        top = pinned = clamp(pinned, height)
    rows = lines[top : top + height]
    sys.stdout.write("\x1b[H" + "\x1b[K\r\n".join(rows) + "\x1b[K\x1b[J")
    sys.stdout.flush()


def main():
    global cursor, pinned, images

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(sys.argv[1])

    if "--images" in sys.argv[2:]:
        from mark_image import Images

        def send_image(image_id, cols, rows, png):
            header = f"I {image_id} {cols} {rows} {len(png)}\n"
            sock.sendall(header.encode() + png)

        images = Images(send_image)

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
            dirty = scrolled = False
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
            new_text = new_dir = None
            while b"\n" in buf:
                header, rest = buf.split(b"\n", 1)
                parts = header.split()
                if parts[0] == b"D":
                    n = int(parts[1])
                    if len(rest) < n:
                        break
                    new_dir = rest[:n].decode("utf-8", "replace")
                    rest = rest[n:]
                elif parts[0] == b"S":
                    scroll(parts[1])
                    scrolled = True
                else:
                    if parts[0] == b"T":
                        n = int(parts[2])
                        if len(rest) < n:
                            break
                        new_text = rest[:n].decode("utf-8", "replace")
                        rest = rest[n:]
                    cursor = int(parts[1])
                    pinned = None
                    scrolled = False
                buf = rest
                dirty = True

            changed = new_text is not None and new_text != text
            if new_text is not None:
                text = new_text
            # Relative image paths now point elsewhere.
            if images and new_dir is not None and new_dir != images.base:
                images.base = new_dir
                cache.clear()
                changed = True
            if changed:
                render(text)
            if dirty:
                draw()
            if scrolled:
                height = os.get_terminal_size().lines
                anchor = source_line(top + height // 3)
                sock.sendall(f"L {source_line(top)} {anchor}\n".encode())
    finally:
        sys.stdout.write("\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
