"""Live markdown viewer driven by Neovim over a Unix socket.

Neovim sends the buffer text, cursor moves and scrolls of the preview window
(see protocol). The view follows the source cursor, which sits a third of
the way down, until the preview is scrolled; then Neovim is told which
source lines to show so it can follow the preview instead. With --images,
image-only blocks become kitty placeholders (images) and each new image is
sent for Neovim to upload to the host terminal.

Rendering and caching live in document; cursor moves only re-slice cached
lines.
"""

import os
import selectors
import signal
import socket
import sys

from rich.console import Console

from richmdviewnvim.document import Document
from richmdviewnvim.markdown import THEME
from richmdviewnvim.protocol import decode, encode


class Viewport:
    """The rows of the document on screen.

    It follows the source cursor until the preview is scrolled, then stays
    pinned where it was scrolled to until the cursor moves again.
    """

    def __init__(self, doc: Document) -> None:
        self.doc = doc
        self.cursor = 1  # 1-based source line
        self.top = 0  # first visible row, as last drawn
        self.pinned: int | None = None  # row set by scrolling
        self.resize()

    def resize(self) -> None:
        self.height = os.get_terminal_size().lines

    def follow(self, cursor: int) -> None:
        self.cursor = cursor
        self.pinned = None

    def scroll(self, arg: str) -> None:
        """Scroll by a number of rows, or to "top" / "bottom"."""
        if arg == "top":
            row = 0
        elif arg == "bottom":
            row = len(self.doc.lines)
        else:
            row = (self.top if self.pinned is None else self.pinned) + int(arg)
        self.pinned = self._clamp(row)

    def anchor(self) -> tuple[int, int]:
        """Source lines for the top row and the row a third of the way down,
        where the cursor sits while following."""
        doc, third = self.doc, self.top + self.height // 3
        return doc.line_of(self.top), doc.line_of(third)

    def draw(self) -> None:
        if self.pinned is None:
            row = self.doc.row_of(self.cursor) - self.height // 3
            self.top = self._clamp(row)
        else:
            self.top = self.pinned = self._clamp(self.pinned)
        rows = self.doc.lines[self.top : self.top + self.height]
        # Each row is cleared before it is drawn: after a full-width row
        # the cursor waits to wrap, and clearing there erases its last cell.
        out = "\x1b[H" + "\r\n".join("\x1b[K" + row for row in rows)
        if len(rows) < self.height:
            out += f"\x1b[{len(rows) + 1}H\x1b[J"
        sys.stdout.write(out)
        sys.stdout.flush()

    def _clamp(self, row: int) -> int:
        return max(0, min(row, len(self.doc.lines) - self.height))


def main() -> None:
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(sys.argv[1])

    images = None
    if "--images" in sys.argv[2:]:
        # Imported only here, so Pillow is only loaded when images are on.
        from richmdviewnvim.images import Images

        def send_image(
            image_id: int, cols: int, rows: int, png: bytes
        ) -> None:
            sock.sendall(encode("I", image_id, cols, rows, payload=png))

        def free_image(image_id: int) -> None:
            sock.sendall(encode("D", image_id))

        images = Images(send_image, free_image)

    console = Console(force_terminal=True, theme=THEME)
    doc = Document(console, images)
    view = Viewport(doc)

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
    buf = bytearray()  # grows in place, unlike bytes, for big messages
    try:
        while True:
            dirty = scrolled = False
            for key, _ in sel.select():
                if key.fileobj is wake_r:
                    wake_r.recv(4096)
                    console.size = os.get_terminal_size()
                    view.resize()
                    doc.resize()
                    dirty = True
                    continue
                chunk = sock.recv(1 << 16)
                if not chunk:
                    return
                buf += chunk

            # Apply every complete message; only the latest text matters.
            messages, buf = decode(buf)
            update = None
            for msg in messages:
                if msg.kind == "S":
                    view.scroll(msg.args[0])
                    scrolled = True
                    continue
                if msg.kind == "T":
                    ndir = int(msg.args[1])
                    update = (
                        msg.payload[ndir:].decode("utf-8", "replace"),
                        msg.payload[:ndir].decode("utf-8", "replace"),
                    )
                view.follow(int(msg.args[0]))
                scrolled = False

            if update is not None:
                doc.update(*update)
            if dirty or messages:
                view.draw()
            if scrolled:
                sock.sendall(encode("L", *view.anchor()))
    finally:
        sys.stdout.write("\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()
