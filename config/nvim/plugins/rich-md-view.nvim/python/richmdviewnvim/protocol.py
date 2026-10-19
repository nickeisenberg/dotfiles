"""Messages between Neovim and the viewer, over a Unix socket.

Every message has the same frame, in both directions:

  <kind> <args...> <nbytes>\\n<payload>

where nbytes is the payload length in bytes, 0 when there is none.

Neovim to viewer:

  T <cursor> <ndir>      payload: buffer directory (ndir bytes), then text
  C <cursor>             cursor moved, text unchanged
  S <rows|top|bottom>    scroll by rows, from the preview window

Text and cursor messages make the view follow the cursor (1-based) again;
scroll messages pin it until the next one.

Viewer to Neovim:

  L <topline> <cursor>          after a scroll: source lines to show, so
                                Neovim can match
  I <id> <cols> <rows>          payload: PNG to upload to the terminal
  D <id>                        an upload that is no longer shown, to free

lua/rich-md-view/protocol.lua is the Neovim side of this.
"""

from typing import NamedTuple


class Message(NamedTuple):
    kind: str
    args: list[str]
    payload: bytes


def encode(kind: str, *args: object, payload: bytes = b"") -> bytes:
    header = " ".join([kind, *map(str, args), str(len(payload))])
    return header.encode() + b"\n" + payload


def decode(buf: bytearray) -> tuple[list[Message], bytearray]:
    """Complete messages at the start of buf, and the bytes left over."""
    messages = []
    while (nl := buf.find(b"\n")) >= 0:
        kind, *args, size = buf[:nl].decode().split(" ")
        end = nl + 1 + int(size)
        if len(buf) < end:
            break
        messages.append(Message(kind, args, bytes(buf[nl + 1 : end])))
        buf = buf[end:]
    return messages, buf
