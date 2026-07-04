#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tkinter as tk
from dataclasses import dataclass
from tkinter import font

###############################################################################
# Configuration
###############################################################################

LOCK_COMMAND = [
    "i3lock",
]

SHUTDOWN_COMMAND = [
    "systemctl",
    "poweroff",
]

REBOOT_COMMAND = [
    "systemctl",
    "reboot",
]


@dataclass
class MenuItem:
    text: str
    command: list[str]


MENU = [
    MenuItem("󰌾  Lock", LOCK_COMMAND),
    MenuItem("󰐥  Shutdown", SHUTDOWN_COMMAND),
    MenuItem("󰜉  Reboot", REBOOT_COMMAND),
]


###############################################################################
# Menu
###############################################################################


class PowerMenu:
    WIDTH = 340
    HEIGHT = 180

    BG = "#1e1e2e"
    FG = "#cdd6f4"

    SELECT_BG = "#89b4fa"
    SELECT_FG = "#11111b"

    FONT_SIZE = 18

    def __init__(self) -> None:

        self.selection = 0

        self.root = tk.Tk()

        # self.root.overrideredirect(True)
        self.root.configure(bg=self.BG)

        self.root.attributes("-topmost", True)

        try:
            self.root.attributes("-alpha", 0.97)
        except tk.TclError:
            pass

        self.center_window()

        self.font = font.Font(
            family="Noto Sans",
            size=self.FONT_SIZE,
        )

        self.labels: list[tk.Label] = []

        frame = tk.Frame(
            self.root,
            bg=self.BG,
            padx=25,
            pady=25,
        )

        frame.pack(fill="both", expand=True)

        for item in MENU:
            label = tk.Label(
                frame,
                text=item.text,
                anchor="w",
                bg=self.BG,
                fg=self.FG,
                font=self.font,
                padx=15,
                pady=6,
            )

            label.pack(fill="x", pady=2)

            self.labels.append(label)

        self.update_selection()

        #######################################################################
        # Keys
        #######################################################################

        self.root.bind("<Up>", self.up)
        self.root.bind("<Down>", self.down)
        self.root.bind("<Control-n>", self.down)
        self.root.bind("<Control-p>", self.up)
        self.root.bind("k", self.up)
        self.root.bind("j", self.down)
        self.root.bind("<Return>", self.execute)
        self.root.bind("<FocusOut>", self.quit)
        self.root.focus_force()

    ###########################################################################

    def center_window(self) -> None:

        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()

        x = (screen_width - self.WIDTH) // 2
        y = (screen_height - self.HEIGHT) // 2

        self.root.geometry(f"{self.WIDTH}x{self.HEIGHT}+{x}+{y}")

    ###########################################################################

    def update_selection(self) -> None:

        for i, label in enumerate(self.labels):
            if i == self.selection:
                label.configure(
                    bg=self.SELECT_BG,
                    fg=self.SELECT_FG,
                )

            else:
                label.configure(
                    bg=self.BG,
                    fg=self.FG,
                )

    ###########################################################################

    def up(self, event=None):

        self.selection -= 1

        if self.selection < 0:
            self.selection = len(MENU) - 1

        self.update_selection()

    ###########################################################################

    def down(self, event=None):

        self.selection += 1

        if self.selection >= len(MENU):
            self.selection = 0

        self.update_selection()

    ###########################################################################

    def execute(self, event=None):

        self.root.destroy()

        subprocess.Popen(MENU[self.selection].command)

    ###########################################################################

    def quit(self, event=None):

        self.root.destroy()

    ###########################################################################

    def run(self):

        self.root.mainloop()


###############################################################################


def main():

    PowerMenu().run()


if __name__ == "__main__":
    main()
