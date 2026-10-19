"""Desktop notifications, sounds and dialogs for macOS and Linux.

Everything shells out to tools that ship with the OS, so there are no Python
dependencies. If a tool is missing, the message still lands in the log.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

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


class DesktopNotifier:
    """What the Timer talks to. Tests swap in a fake."""

    notify = staticmethod(notify)
    play_sound = staticmethod(play_sound)
    prompt = staticmethod(prompt)
