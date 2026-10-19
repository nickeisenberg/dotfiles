"""Background process + the tiny JSON-over-Unix-socket protocol the CLI uses."""

from __future__ import annotations

import fcntl
import json
import os
import signal
import socket
import subprocess
import sys
import time
from dataclasses import asdict, fields
from pathlib import Path

from . import child_env
from .notify import DesktopNotifier
from .timer import Settings, Timer

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "take-a-break"
SOCKET_PATH = STATE_DIR / "tab.sock"
LOG_PATH = STATE_DIR / "tab.log"
LOCK_PATH = STATE_DIR / "tab.lock"

_SETTING_TYPES = {f.name: f.type for f in fields(Settings)}
_COERCE = {"float": float, "int": int, "bool": bool}  # field types are strings (PEP 563)


# -- client side ------------------------------------------------------------

class NotRunning(Exception):
    pass


def send(cmd: str, **args) -> dict:
    """Send one command to the daemon and return its reply."""
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(5)
            s.connect(str(SOCKET_PATH))
            s.sendall(json.dumps({"cmd": cmd, "args": args}).encode() + b"\n")
            reply = _read_line(s)
    except (FileNotFoundError, ConnectionRefusedError):
        raise NotRunning from None
    if not reply:
        raise NotRunning
    return json.loads(reply)


def is_running() -> bool:
    try:
        send("status")
        return True
    except (NotRunning, OSError):
        return False


def find_processes() -> list[dict]:
    """All take-a-break daemons on this machine, found via ``ps`` so that
    stuck or orphaned ones show up too (works on macOS and Linux)."""
    out = subprocess.run(["ps", "-eo", "pid=,etime=,args="], capture_output=True, text=True).stdout
    procs = []
    for line in out.splitlines():
        parts = line.split(None, 2)
        if len(parts) == 3 and "take_a_break _serve" in parts[2] and int(parts[0]) != os.getpid():
            procs.append({"pid": int(parts[0]), "uptime": parts[1]})
    return procs


def kill(pids: list[int], timeout: float = 3) -> list[int]:
    """SIGTERM the given daemons, SIGKILL any that linger. Returns killed pids."""
    killed = []
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
            killed.append(pid)
        except ProcessLookupError:
            pass
    deadline = time.monotonic() + timeout
    alive = list(killed)
    while alive and time.monotonic() < deadline:
        time.sleep(0.1)
        alive = [p for p in alive if _alive(p)]
    for pid in alive:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if not find_processes():
        SOCKET_PATH.unlink(missing_ok=True)
    return killed


def _alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def spawn(settings: Settings) -> None:
    """Start the daemon as a detached process and wait until it answers."""
    _make_state_dir()
    with open(LOG_PATH, "a") as log:
        proc = subprocess.Popen(
            [sys.executable, "-m", "take_a_break", "_serve", json.dumps(asdict(settings))],
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=log,
            start_new_session=True,  # survive the terminal closing
            env=child_env(),
        )
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline and proc.poll() is None:
        if is_running():
            return
        time.sleep(0.1)
    raise RuntimeError(f"daemon did not start, see {LOG_PATH}")


def _make_state_dir() -> None:
    # Private: anyone who can reach the socket can control the timer.
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)


# -- server side ------------------------------------------------------------

def serve(settings: Settings) -> None:
    """Run the timer loop and answer CLI commands until stopped or finished."""
    _make_state_dir()
    # One daemon at a time. Held until this process exits, so only the
    # holder ever touches the socket file.
    lock = open(LOCK_PATH, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit("tab: another take-a-break daemon is already running")
    SOCKET_PATH.unlink(missing_ok=True)  # left over from a daemon that was killed

    running = True

    def _stop(*_):
        nonlocal running
        running = False

    signal.signal(signal.SIGTERM, _stop)
    signal.signal(signal.SIGINT, _stop)

    timer = Timer(settings, DesktopNotifier())
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(SOCKET_PATH))
    server.listen()
    server.settimeout(0.5)
    _log(f"started (pid {os.getpid()}): {asdict(settings)}")
    try:
        timer.start()
        while running and not timer.finished:
            try:
                timer.tick()
            except Exception as e:  # log it and keep the timer alive
                _log(f"tick failed: {e!r}")
            try:
                conn, _ = server.accept()
            except socket.timeout:
                continue
            with conn:
                conn.settimeout(2)
                reply, stop = _handle(timer, conn)
                try:
                    conn.sendall(json.dumps(reply).encode() + b"\n")
                except OSError:
                    pass
            if stop:
                running = False
    finally:
        timer.close()
        server.close()
        SOCKET_PATH.unlink(missing_ok=True)
        lock.close()
        _log("stopped")


def _handle(timer: Timer, conn: socket.socket) -> tuple[dict, bool]:
    try:
        request = json.loads(_read_line(conn))
        cmd, args = request["cmd"], request.get("args", {})
        if cmd == "status":
            message = ""
        elif cmd == "pause":
            message = timer.pause()
        elif cmd == "resume":
            message = timer.resume()
        elif cmd == "skip":
            message = timer.skip()
        elif cmd == "confirm":
            message = timer.confirm()
        elif cmd == "window":
            opened = timer.notifier.show_window()
            message = "window open" if opened else "no window support here (needs tkinter and a display)"
        elif cmd == "set":
            message = timer.update(**_check_settings(args))
        elif cmd == "stop":
            return {"ok": True, "message": "stopped", "status": timer.status()}, True
        else:
            raise ValueError(f"unknown command {cmd!r}")
        if message:
            _log(f"{cmd}: {message}")
        return {"ok": True, "message": message, "status": {**timer.status(), "pid": os.getpid()}}, False
    except Exception as e:  # never let a bad request kill the daemon
        return {"ok": False, "error": str(e)}, False


def _check_settings(args: dict) -> dict:
    """Validate a ``set`` request before it touches the timer."""
    unknown = set(args) - set(_SETTING_TYPES)
    if unknown:
        raise ValueError(f"unknown settings: {', '.join(sorted(unknown))}")
    checked = {}
    for name, value in args.items():
        kind = _COERCE[_SETTING_TYPES[name]]
        if kind is bool:
            if not isinstance(value, bool):
                raise ValueError(f"{name} must be true or false")
        elif not isinstance(value, (int, float)) or isinstance(value, bool) or not 0 <= value < float("inf"):
            raise ValueError(f"{name} must be a number, 0 or more")
        checked[name] = kind(value)
    for name in ("work", "rest", "long_rest"):
        if checked.get(name, 1) <= 0:
            raise ValueError(f"{name} must be positive")
    return checked


def _read_line(sock: socket.socket) -> str:
    data = b""
    while not data.endswith(b"\n"):
        chunk = sock.recv(4096)
        if not chunk:
            break
        data += chunk
    return data.decode()


def _log(message: str) -> None:
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {message}", flush=True)
