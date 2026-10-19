"""Command line interface: ``tab start``, ``tab status``, ``tab pause`` ..."""

from __future__ import annotations

import argparse
import sys
import time

from . import daemon
from .durations import format_clock, format_duration, parse_duration
from .timer import LABELS, Settings

EXAMPLES = """\
examples:
  tab start                 30 min work / 10 min break (defaults)
  tab start 25 5            25 min work / 5 min break
  tab start -w 50m -b 10m --long-break 30m --long-every 3
  tab start --confirm       wait for a "Start Break" / "Start Work" click
  tab status --watch        live countdown
  tab set -b 15             change the break length while running
  tab skip                  jump to the next phase now
  tab ps / tab kill         list / force-kill timer processes
"""


def _duration(text: str) -> float:
    try:
        return parse_duration(text)
    except ValueError as e:
        raise argparse.ArgumentTypeError(str(e))


def _timing_options(parser: argparse.ArgumentParser) -> None:
    g = parser.add_argument_group("timing")
    g.add_argument("-w", "--work", type=_duration, metavar="DUR", help="work length (default 30m)")
    g.add_argument("-b", "--break", dest="rest", type=_duration, metavar="DUR", help="break length (default 10m)")
    g.add_argument("-l", "--long-break", dest="long_rest", type=_duration, metavar="DUR",
                   help="long break length (default 20m)")
    g.add_argument("-e", "--long-every", type=int, metavar="N",
                   help="long break after every N work sessions (default 0 = never)")
    g.add_argument("-n", "--cycles", type=int, metavar="N", help="stop after N work sessions (default 0 = forever)")
    g.add_argument("--confirm", action=argparse.BooleanOptionalAction, default=None,
                   help="wait for a button click before each timer starts (default off)")
    g.add_argument("--sound", action=argparse.BooleanOptionalAction, default=None,
                   help="play a sound when a phase ends (default on)")


def _given_settings(args: argparse.Namespace) -> dict:
    names = ("work", "rest", "long_rest", "long_every", "cycles", "confirm", "sound")
    given = {n: getattr(args, n) for n in names if getattr(args, n) is not None}
    for n in ("long_every", "cycles"):
        if given.get(n, 0) < 0:
            sys.exit(f"tab: --{n.replace('_', '-')} must be 0 or more")
    return given


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tab",
        description="Take a break: a work/break timer that runs in the background.",
        epilog="Durations: a plain number is minutes, or use 90s, 25m, 1h30m.\n\n" + EXAMPLES,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", metavar="COMMAND")

    start = sub.add_parser("start", help="start the timer in the background")
    start.add_argument("work_pos", nargs="?", type=_duration, metavar="WORK", help="work length, e.g. 30")
    start.add_argument("rest_pos", nargs="?", type=_duration, metavar="BREAK", help="break length, e.g. 10")
    start.add_argument("-f", "--foreground", action="store_true", help="run in this terminal instead")
    _timing_options(start)

    status = sub.add_parser("status", help="show what's happening (default command)")
    status.add_argument("--watch", action="store_true", help="live countdown, Ctrl-C to exit")

    setp = sub.add_parser("set", help="change settings while running")
    _timing_options(setp)

    sub.add_parser("pause", help="pause the countdown")
    sub.add_parser("resume", help="resume after pause")
    sub.add_parser("skip", help="end the current phase now and move to the next")
    sub.add_parser("stop", help="stop the background timer")
    sub.add_parser("ps", help="list running take-a-break processes")
    killp = sub.add_parser("kill", help="force-kill take-a-break processes (all, or the given PIDs)")
    killp.add_argument("pids", nargs="*", type=int, metavar="PID")
    log = sub.add_parser("log", help="show the daemon log")
    log.add_argument("-n", type=int, default=20, help="number of lines (default 20)")

    return parser


def main(argv: list[str] | None = None) -> None:
    args = build_parser().parse_args(argv)
    command = args.command or "status"
    try:
        if command == "start":
            cmd_start(args)
        elif command == "status":
            cmd_status(args.watch if args.command else False)
        elif command == "set":
            changes = _given_settings(args)
            if not changes:
                sys.exit("tab set: nothing to change (see tab set -h)")
            _print_reply(daemon.send("set", **changes))
        elif command == "log":
            cmd_log(args.n)
        elif command == "ps":
            cmd_ps()
        elif command == "kill":
            cmd_kill(args.pids)
        else:  # pause / resume / skip / stop
            _print_reply(daemon.send(command), show_status=command != "stop")
    except daemon.NotRunning:
        sys.exit("tab is not running. Start it with: tab start")
    except KeyboardInterrupt:
        print()


def cmd_start(args: argparse.Namespace) -> None:
    given = _given_settings(args)
    for pos, name, flag in ((args.work_pos, "work", "--work"), (args.rest_pos, "rest", "--break")):
        if pos is not None:
            if name in given:
                sys.exit(f"tab start: give the {name if name == 'work' else 'break'} length "
                         f"either positionally or with {flag}, not both")
            given[name] = pos
    if daemon.is_running():
        sys.exit("tab is already running. Use `tab set ...` to change it, or `tab stop` first.")
    if daemon.find_processes():
        sys.exit("A take-a-break process exists but isn't responding. Clear it with `tab kill`.")
    settings = Settings(**given)
    if args.foreground:
        print(f"Running in the foreground. {_settings_line(vars(settings))}. Ctrl-C to stop.")
        daemon.serve(settings)
        return
    daemon.spawn(settings)
    print(f"Started. {_settings_line(vars(settings))}")
    print("Check on it with `tab status`, stop with `tab stop`.")


def cmd_status(watch: bool) -> None:
    if not watch:
        print(_status_text(daemon.send("status")["status"]))
        return
    while True:
        try:
            status = daemon.send("status")["status"]
        except daemon.NotRunning:
            print("\ntab stopped.")
            return
        sys.stdout.write("\r\033[K" + _status_text(status).splitlines()[0])
        sys.stdout.flush()
        time.sleep(1)


def cmd_ps() -> None:
    procs = daemon.find_processes()
    if not procs:
        print("No take-a-break processes running.")
        return
    try:
        status = daemon.send("status")["status"]
    except (daemon.NotRunning, OSError):
        status = None
    print(f"{'PID':>7}  {'UPTIME':>10}  STATE")
    for p in procs:
        if status and status.get("pid") == p["pid"]:
            state = _status_text(status).splitlines()[0]
        else:
            state = "not responding (stuck or orphaned) - use `tab kill`"
        print(f"{p['pid']:>7}  {p['uptime']:>10}  {state}")


def cmd_kill(pids: list[int]) -> None:
    running = {p["pid"] for p in daemon.find_processes()}
    if pids:
        unknown = [p for p in pids if p not in running]
        if unknown:
            sys.exit(f"tab kill: not a take-a-break process: {', '.join(map(str, unknown))}")
    else:
        pids = sorted(running)
    if not pids:
        print("No take-a-break processes running.")
        return
    killed = daemon.kill(pids)
    print(f"Killed {', '.join(map(str, killed))}." if killed else "Nothing to kill.")


def cmd_log(lines: int) -> None:
    try:
        text = daemon.LOG_PATH.read_text()
    except FileNotFoundError:
        print("no log yet")
        return
    print("\n".join(text.splitlines()[-lines:]))


def _print_reply(reply: dict, show_status: bool = True) -> None:
    if not reply.get("ok"):
        sys.exit(f"tab: {reply.get('error')}")
    if reply.get("message"):
        print(reply["message"].capitalize())
    if show_status:
        print(_status_text(reply["status"]))


def _status_text(status: dict) -> str:
    s = status["settings"]
    label = LABELS[status["phase"]]
    session = f"session {status['cycle']}" + (f"/{s['cycles']}" if s["cycles"] else "")
    if status["finished"]:
        line = "All sessions done."
    elif status["pending"]:
        button = "Start Work" if status["pending"] == "work" else "Start Break"
        line = f"Waiting for you to click \"{button}\"  ({session})"
    else:
        paused = "  [paused]" if status["paused"] else ""
        line = f"{label}: {format_clock(status['remaining'])} left  ({session}){paused}"
    return f"{line}\n{_settings_line(s)}"


def _settings_line(s: dict) -> str:
    parts = [f"work {format_duration(s['work'])}", f"break {format_duration(s['rest'])}"]
    if s["long_every"]:
        parts.append(f"long break {format_duration(s['long_rest'])} every {s['long_every']}")
    if s["cycles"]:
        parts.append(f"{s['cycles']} sessions")
    if s["confirm"]:
        parts.append("confirm on")
    if not s["sound"]:
        parts.append("sound off")
    return ", ".join(parts)
