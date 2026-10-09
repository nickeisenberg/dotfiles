#!/usr/bin/env python3

from __future__ import annotations

import subprocess
from dataclasses import dataclass

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Center, Middle
from textual.widgets import Label, ListItem, ListView

###############################################################################
# Configuration
###############################################################################

LOCK_COMMAND = ["i3lock", "--color", "000000"]

LOGOUT_COMMAND = ["qtile", "cmd-obj", "-o", "cmd", "-f", "shutdown"]

SHUTDOWN_COMMAND = ["systemctl", "poweroff"]

REBOOT_COMMAND = ["systemctl", "reboot"]


@dataclass(frozen=True)
class MenuItem:
    text: str
    command: list[str]


MENU = [
    MenuItem("Lock", LOCK_COMMAND),
    MenuItem("Logout", LOGOUT_COMMAND),
    MenuItem("Shutdown", SHUTDOWN_COMMAND),
    MenuItem("Reboot", REBOOT_COMMAND),
]


###############################################################################
# Menu
###############################################################################


class PowerMenu(App[None]):
    CSS = """
    Screen {
        background: #1e1e2e;
        align: center middle;
    }

    #menu {
        width: 34;
        height: auto;
        max-height: 14;
        padding: 1 2;
        background: #1e1e2e;
        border: none;
    }

    ListView {
        height: auto;
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
        Binding("escape", "quit", "Quit", show=False),
        Binding("q", "quit", "Quit", show=False),
        Binding("j", "down", "Down", show=False, priority=True),
        Binding("k", "up", "Up", show=False, priority=True),
        Binding("ctrl+n", "down", "Down", show=False, priority=True),
        Binding("ctrl+p", "up", "Up", show=False, priority=True),
        Binding("enter", "execute", "Execute", show=False, priority=True),
    ]

    def compose(self) -> ComposeResult:
        with Center(), Middle():
            yield ListView(
                *(ListItem(Label(item.text)) for item in MENU),
                id="menu",
            )

    def on_mount(self) -> None:
        menu = self.query_one("#menu", ListView)
        menu.index = 0
        menu.focus()

    def action_up(self) -> None:
        menu = self.query_one("#menu", ListView)
        index = menu.index if menu.index is not None else 0
        menu.index = (index - 1) % len(MENU)

    def action_down(self) -> None:
        menu = self.query_one("#menu", ListView)
        index = menu.index if menu.index is not None else 0
        menu.index = (index + 1) % len(MENU)

    def action_execute(self) -> None:
        menu = self.query_one("#menu", ListView)

        if menu.index is None:
            return

        command = MENU[menu.index].command
        self.exit(result=None)
        subprocess.Popen(
            command,
            start_new_session=True,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def on_list_view_selected(
        self,
        event: ListView.Selected,
    ) -> None:
        self.action_execute()


###############################################################################
# Entry point
###############################################################################


def main() -> None:
    PowerMenu().run()


if __name__ == "__main__":
    main()
