#!/usr/bin/env python3

from __future__ import annotations

import subprocess
from dataclasses import dataclass

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.widgets import Label, ListItem, ListView


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


class PowerMenu(App[tuple[str, ...] | None]):
    CSS = """
    Screen {
        background: #1e1e2e;
        align: center middle;
    }

    ListView {
        width: 34;
        height: auto;
        max-height: 14;
        padding: 1 2;
        background: #1e1e2e;
        border: none;
    }

    ListItem {
        height: 2;
        padding: 0 1;
        color: #cdd6f4;
        background: #1e1e2e;
    }

    ListItem.--highlight {
        color: #11111b;
        background: #89b4fa;
    }

    ListView:focus {
        border: none;
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
        yield ListView(
            *(ListItem(Label(item.text)) for item in MENU),
            id="menu",
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
    main()
