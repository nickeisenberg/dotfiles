"""The little timer window (tkinter, ships with Python).

It's just another client of the daemon: it polls ``status`` over the socket,
shows the countdown, and sends ``confirm`` when you click Start. Closing it
leaves the timer running in the background; ``tab window`` reopens it.
"""

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys

from . import child_env

POLL_MS = 500


def available() -> bool:
    if importlib.util.find_spec("_tkinter") is None:
        return False
    return sys.platform == "darwin" or bool(os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))


def spawn() -> subprocess.Popen | None:
    """Launch the window as its own process. Its output goes to the daemon log."""
    try:
        return subprocess.Popen([sys.executable, "-m", "take_a_break", "_window"],
                                stdin=subprocess.DEVNULL, env=child_env())
    except OSError as e:
        print(f"could not open the timer window: {e}", flush=True)
        return None


def run() -> None:
    import tkinter as tk

    from . import daemon
    from .durations import format_clock
    from .timer import LABELS

    root = tk.Tk()
    root.title("Take a Break")
    root.resizable(False, False)
    heading = tk.Label(root, font=("Helvetica", 16, "bold"))
    clock = tk.Label(root, font=("Helvetica", 44))
    detail = tk.Label(root, font=("Helvetica", 12))
    button = tk.Button(root, width=12)
    hint = tk.Label(root, font=("Helvetica", 10), fg="gray",
                    text="Closing this window keeps the timer running.\nReopen it with `tab window`.")
    heading.pack(padx=28, pady=(18, 0))
    clock.pack(padx=28)
    detail.pack(padx=28)
    button.pack(pady=12)
    hint.pack(padx=28, pady=(0, 14))

    state: dict[str, str | None] = {"pending": None, "action": None}

    def talk(cmd: str) -> dict | None:
        """Send a command, return the new status (None if it didn't work)."""
        try:
            return daemon.send(cmd)["status"]
        except daemon.NotRunning:
            root.quit()  # the timer is gone, so is the window
        except (OSError, ValueError, KeyError) as e:  # busy daemon or bad reply: retry next poll
            print(f"window: {cmd} failed: {e!r}", flush=True)
        return None

    def show(status: dict) -> None:
        pending, s = status["pending"], status["settings"]
        session = f"Session {status['cycle']}" + (f"/{s['cycles']}" if s["cycles"] else "")
        clock["text"] = format_clock(status["remaining"])
        if pending:
            title, message, label = status["prompt"]
            heading["text"], detail["text"] = title, message
            button["text"], state["action"] = label, "confirm"
        else:
            heading["text"] = LABELS[status["phase"]]
            detail["text"] = session + ("  (paused)" if status["paused"] else "")
            button["text"] = "Resume" if status["paused"] else "Pause"
            state["action"] = "resume" if status["paused"] else "pause"

        if pending and pending != state["pending"]:  # a new prompt: come to the front
            root.deiconify()
            root.lift()
            root.attributes("-topmost", True)
            root.focus_force()
        elif not pending and state["pending"]:
            root.attributes("-topmost", False)
        state["pending"] = pending

    def click(*_) -> None:
        if state["action"]:
            status = talk(state["action"])
            if status:
                show(status)

    def refresh() -> None:
        status = talk("status")
        if status:
            show(status)
        root.after(POLL_MS, refresh)

    button["command"] = click
    root.bind("<Return>", click)
    root.after(0, refresh)
    root.mainloop()
