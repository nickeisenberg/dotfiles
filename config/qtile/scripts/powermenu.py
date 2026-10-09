#!/usr/bin/env python3

from __future__ import annotations

import getpass
import platform
import subprocess
from dataclasses import dataclass
from pathlib import Path

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Vertical
from textual.widgets import Label, ListItem, ListView, Static


@dataclass(frozen=True)
class MenuItem:
    text: str
    command: tuple[str, ...]


MENU = (
    MenuItem("Lock", ("i3lock", "--color", "000000")),
    MenuItem(
        "Logout",
        ("qtile", "cmd-obj", "-o", "cmd", "-f", "shutdown"),
    ),
    MenuItem("Shutdown", ("systemctl", "poweroff")),
    MenuItem("Reboot", ("systemctl", "reboot")),
)


def get_uptime() -> str:
    try:
        seconds = float(Path("/proc/uptime").read_text().split()[0])
    except (OSError, ValueError, IndexError):
        return "unknown"

    minutes = int(seconds // 60)
    days, minutes = divmod(minutes, 1440)
    hours, minutes = divmod(minutes, 60)

    parts = []

    if days:
        parts.append(f"{days}d")

    if hours or days:
        parts.append(f"{hours}h")

    parts.append(f"{minutes}m")

    return " ".join(parts)


class PowerMenu(App[tuple[str, ...] | None]):
    CSS = """
    Screen {
        background: ansi_black;
        align: center middle;
    }
    
    #panel {
        width: 46;
        height: auto;
        padding: 1 2;
        background: ansi_black;
        border: solid ansi_bright_black;
    }
    
    #header {
        width: 100%;
        height: 1;
        color: ansi_green;
        text-style: bold;
    }
    
    #uptime {
        width: 100%;
        height: 1;
        color: ansi_bright_black;
        margin-bottom: 1;
    }
    
    .separator {
        width: 100%;
        height: 1;
        color: ansi_bright_black;
    }
    
    #description {
        height: 1;
        color: ansi_bright_black;
        margin: 1 0;
    }
    
    ListView {
        width: 100%;
        height: auto;
        background: transparent;
        border: none;
        padding: 0;
    }
    
    ListItem {
        height: 1;
        padding: 0 1;
        color: ansi_white;
        background: transparent;
    }
    
    ListItem Label {
        width: 100%;
        color: ansi_white;
        background: transparent;
    }
    
    ListItem.-highlight {
        color: ansi_black;
        background: ansi_blue;
        text-style: bold;
    }
    
    ListItem.-highlight Label {
        color: ansi_black;
        background: ansi_blue;
        text-style: bold;
    }
    
    ListView:focus {
        border: none;
    }
    
    #footer {
        width: 100%;
        height: 1;
        color: ansi_bright_black;
        margin-top: 1;
    }
    """

    BINDINGS = [
        Binding("escape", "quit", show=False),
        Binding("q", "quit", show=False),
        Binding("j", "move(1)", show=False, priority=True),
        Binding("k", "move(-1)", show=False, priority=True),
        Binding("ctrl+n", "move(1)", show=False, priority=True),
        Binding("ctrl+p", "move(-1)", show=False, priority=True),
        Binding("enter", "execute", show=False, priority=True),
    ]

    def compose(self) -> ComposeResult:
        username = getpass.getuser()
        hostname = platform.node().split(".")[0]
        uptime = get_uptime()

        with Vertical(id="panel"):
            yield Static(
                f"{username}@{hostname}",
                id="header",
            )

            yield Static(
                f"uptime  {uptime}",
                id="uptime",
            )

            yield Static("─" * 38, classes="separator")
            yield Static("Select an action:", id="description")

            yield ListView(
                *(
                    ListItem(Label(f"  {i:02d}   {item.text}"))
                    for i, item in enumerate(MENU, start=1)
                ),
                id="menu",
            )

            yield Static("─" * 38, classes="separator")
            yield Static(
                "j/k navigate  ·  enter select  ·  q quit",
                id="footer",
            )

    def on_mount(self) -> None:
        menu = self.query_one(ListView)
        menu.index = 0
        menu.focus()

    def action_move(self, offset: int) -> None:
        menu = self.query_one(ListView)
        index = menu.index or 0
        menu.index = (index + offset) % len(MENU)

    def action_execute(self) -> None:
        menu = self.query_one(ListView)

        if menu.index is not None:
            self.exit(MENU[menu.index].command)

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        self.action_execute()


def main() -> None:
    command = PowerMenu().run()

    if command is not None:
        subprocess.Popen(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )


if __name__ == "__main__":
    app = PowerMenu(ansi_color=True)
    command = app.run()
