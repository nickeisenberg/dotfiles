#!/usr/bin/env python3

import re
import subprocess

def get_active_monitors():
    verbose = [
        x for x in subprocess.run(
            "xrandr --listmonitors",
            shell=True,
            stdout=subprocess.PIPE
        ).stdout.decode().split("\n")
        if len(x) > 1
    ]
    active_dual_monitors = {}
    for l in verbose:
        m = re.match(r'^\s*([0-9]*):\s*\+(\S*)\s*.*', l)
        if m:
            if m.group(1) is not None and m.group(2) is not None:
                active_dual_monitors[m.group(2)] = {"primary": int(m.group(1)) == 0}
    return active_dual_monitors

def get_brightness_for_active_monitors():
    active_monitors = get_active_monitors()
    verbose = [
        x for x in subprocess.run(
            "xrandr --verbose",
            shell=True,
            stdout=subprocess.PIPE
        ).stdout.decode().split("\n")
        if len(x) > 1
    ]
    current_monitor = None
    for line in verbose:
        monitor = re.match(r'^([a-zA-Z][a-zA-Z0-9-]*)\s+(connected|disconnected).*' , line)
        if monitor is not None:
            current_monitor = monitor.group(1)
        elif current_monitor is not None:
            brightness = re.match(r'^\s*(Brightness:)\s*([0-9]*\.[0-9]*).*' , line)
            if brightness is not None:
                if current_monitor in active_monitors:
                    active_monitors[current_monitor]["brightness"] = float(brightness.group(2))
    return active_monitors

get_brightness_for_active_monitors()
