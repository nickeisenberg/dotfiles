"""Desktop notifications, sounds and dialogs for macOS and Linux.

Everything shells out to tools that ship with the OS, so there are no Python
dependencies. If a tool is missing, the message still lands in the log.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from . import window

APP_NAME = "Take a Break"
IS_MAC = sys.platform == "darwin"

MAC_SOUND = "/System/Library/Sounds/Glass.aiff"
LINUX_SOUNDS = [
    "/usr/share/sounds/freedesktop/stereo/complete.oga",
    "/usr/share/sounds/freedesktop/stereo/bell.oga",
]


def _spawn(args: list[str]) -> subprocess.Popen | None:
    try:
        return subprocess.Popen(
            args, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except OSError as e:
        print(f"could not run {args[0]}: {e}", flush=True)
        return None


def _applescript_str(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def notify(title: str, message: str) -> None:
    print(f"notify: {title} - {message}", flush=True)
    if IS_MAC:
        script = f"display notification {_applescript_str(message)} with title {_applescript_str(title)}"
        _spawn(["osascript", "-e", script])
    elif shutil.which("notify-send"):
        _spawn(["notify-send", "--app-name", APP_NAME, title, message])


def play_sound() -> None:
    if IS_MAC:
        _spawn(["afplay", MAC_SOUND])
        return
    sound = next((s for s in LINUX_SOUNDS if Path(s).exists()), None)
    if not sound:
        return
    for player in ("paplay", "pw-play", "aplay"):
        if shutil.which(player):
            _spawn([player, sound])
            return


def prompt(title: str, message: str, button: str) -> subprocess.Popen | None:
    """Show a dialog with one button. Returns the dialog process (it exits when
    the button is clicked), or None if no dialog tool is available."""
    print(f"prompt: {title} - {message} [{button}]", flush=True)
    if IS_MAC:
        script = (
            f"display dialog {_applescript_str(message)} with title {_applescript_str(title)} "
            f"buttons {{{_applescript_str(button)}}} default button 1 with icon note"
        )
        return _spawn(["osascript", "-e", script])
    if shutil.which("zenity"):
        return _spawn(["zenity", "--info", f"--title={title}", f"--text={message}", f"--ok-label={button}"])
    if shutil.which("kdialog"):
        return _spawn(["kdialog", "--title", title, "--msgbox", message])
    return None


class Dialog:
    """A one-button dialog process. It's answered when the process exits."""

    def __init__(self, proc: subprocess.Popen):
        self.proc = proc

    def poll(self) -> int | None:
        return self.proc.poll()

    def close(self) -> None:
        if self.proc.poll() is None:
            self.proc.terminate()


class WindowPrompt(Dialog):
    """The timer window showing a Start button. The click arrives as a
    ``confirm`` command over the socket; closing the window counts as a click.
    It stays open afterwards to show the countdown.

    If the window crashes instead (e.g. Tk can't reach a display), fall back
    to a plain dialog rather than treating the crash as a click."""

    def __init__(self, proc: subprocess.Popen, text: tuple[str, str, str]):
        super().__init__(proc)
        self.text = text
        self.fallback: Dialog | None = None

    def poll(self) -> int | None:
        if self.fallback is not None:
            return self.fallback.poll()
        code = self.proc.poll()
        if code:  # nonzero: crashed, not closed by the user
            print(f"timer window exited with code {code}, using a dialog instead", flush=True)
            proc = prompt(*self.text)
            if proc is None:
                return code
            self.fallback = Dialog(proc)
            return None
        return code

    def close(self) -> None:
        if self.fallback is not None:
            self.fallback.close()  # the window itself stays open as the countdown


class DesktopNotifier:
    """What the Timer talks to. Tests swap in a fake."""

    notify = staticmethod(notify)
    play_sound = staticmethod(play_sound)

    def __init__(self):
        self._window: subprocess.Popen | None = None

    def show_window(self) -> subprocess.Popen | None:
        """Open the timer window, or reuse the one that's already open."""
        if self._window is None or self._window.poll() is not None:
            self._window = window.spawn() if window.available() else None
        return self._window

    def prompt(self, title: str, message: str, button: str) -> Dialog | None:
        win = self.show_window()
        if win is not None:
            print(f"prompt (window): {title} - {message} [{button}]", flush=True)
            return WindowPrompt(win, (title, message, button))
        proc = prompt(title, message, button)
        return Dialog(proc) if proc else None
