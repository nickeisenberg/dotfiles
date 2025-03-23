#!/usr/bin/env python3

import re
import subprocess
from typing import Optional


class DualMonitorBrightness:
    def __init__(self):
        self._dual_monitors = None

    @property
    def dual_monitors(self):
        if self._dual_monitors is None:
            self._dual_monitors = self._refresh_dual_monitors()
        return self._dual_monitors

    def increment(self, value: int, monitor_id: Optional[int] = None, 
                  bus_id: Optional[int] = None):
        if monitor_id is None and bus_id is None:
            if len(self.dual_monitors) == 0:
                self._dual_monitors = self._refresh_dual_monitors()
                if len(self.dual_monitors) == 0:
                    raise NotImplementedError("blahhh")
            monitor_id = list(self.dual_monitors.keys())[0]

        if monitor_id is not None and monitor_id not in self.dual_monitors:
            self._dual_monitors = self._refresh_dual_monitors()
            if monitor_id not in self.dual_monitors:
                raise KeyError("monitor_id not found")

        if bus_id is None:
            bus_id = self.dual_monitors[monitor_id]["bus_id"]

        if monitor_id is None:
            for id in self.dual_monitors:
                if "bus_id" in self.dual_monitors[id]:
                    if self.dual_monitors[id]["bus_id"] == bus_id:
                        monitor_id = id

            if monitor_id is None:
                self._dual_monitors = self._refresh_dual_monitors()

            for id in self.dual_monitors:
                if "bus_id" in self.dual_monitors[id]:
                    if self.dual_monitors[id]["bus_id"] == bus_id:
                        monitor_id = id

            if monitor_id is None:
                raise Exception("monitor_id not found for bus_id")

        current = self.get(monitor_id=monitor_id)
        new = current + value
        self.set(value=new, monitor_id=monitor_id)

        return None

    def get(self, monitor_id: Optional[int] = None, bus_id: Optional[int] = None):
        if monitor_id is None and bus_id is None:
            if len(self.dual_monitors) == 0:
                self._dual_monitors = self._refresh_dual_monitors()
                if len(self.dual_monitors) == 0:
                    raise NotImplementedError("blahhh")
            monitor_id = list(self.dual_monitors.keys())[0]

        if monitor_id is not None and monitor_id not in self.dual_monitors:
            self._dual_monitors = self._refresh_dual_monitors()
            if monitor_id not in self.dual_monitors:
                raise KeyError("monitor_id not found")

        if bus_id is None:
            bus_id = self.dual_monitors[monitor_id]["bus_id"]

        result = subprocess.run(
            f"ddcutil --bus={bus_id} getvcp 10",
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        if len(result.stderr.decode()) > 0:
            raise Exception(result.stderr.decode())

        current = re.match(
            r'^.*(current\svalue\s=)\s*([0-9]*).*',
            result.stdout.decode()
        )
        if current is not None:
            return int(current.group(2))
        else:
            raise Exception("get didnt work")

    def set(self, value: int, monitor_id: Optional[int] = None,
                  bus_id: Optional[int] = None):
        if monitor_id is None and bus_id is None:
            if len(self.dual_monitors) == 0:
                self._dual_monitors = self._refresh_dual_monitors()
                if len(self.dual_monitors) == 0:
                    raise NotImplementedError("blahhh")
            monitor_id = list(self.dual_monitors.keys())[0]

        if monitor_id is not None and monitor_id not in self.dual_monitors:
            self._dual_monitors = self._refresh_dual_monitors()
            if monitor_id not in self.dual_monitors:
                raise KeyError("monitor_id not found")

        if bus_id is None:
            bus_id = self.dual_monitors[monitor_id]["bus_id"]

        if monitor_id is None:
            for id in self.dual_monitors:
                if "bus_id" in self.dual_monitors[id]:
                    if self.dual_monitors[id]["bus_id"] == bus_id:
                        monitor_id = id

            if monitor_id is None:
                self._dual_monitors = self._refresh_dual_monitors()

            for id in self.dual_monitors:
                if "bus_id" in self.dual_monitors[id]:
                    if self.dual_monitors[id]["bus_id"] == bus_id:
                        monitor_id = id

            if monitor_id is None:
                raise Exception("monitor_id not found for bus_id")

        if value > 100:
            value = 100
        elif value < 0:
            value = 0

        bus_id = self.dual_monitors[monitor_id]["bus_id"]
        result = subprocess.run(
            f"ddcutil --bus={bus_id} setvcp 10 {value}",
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        if len(result.stderr.decode()) > 0:
            raise Exception(f"{result.stderr.decode()}")

        self.dual_monitors[monitor_id]["brightness"] = value

    def _refresh_dual_monitors(self):
        detect = subprocess.run(
            "ddcutil detect", shell=True, stdout=subprocess.PIPE
        ).stdout.decode().split("\n")
        active_displays = {}
        for line in detect:
            display = re.match(r'^(Display)\s([0-9]).*', line)
            if display:
                active_displays[int(display.group(2))] = {}
            elif len(active_displays.keys()) > 0:
                current_key = list(active_displays.keys())[-1]
                bus_id = re.match(r'^\s*(I2C\sbus:).*-([0-9]*$)', line)
                if bus_id:
                    active_displays[current_key]["bus_id"] = int(bus_id.group(2))
                    active_displays[current_key]["brightness"] = self.get(
                        bus_id=int(bus_id.group(2))
                    )
                serial = re.match(r'^\s*(Serial\snumber:)\s*(\S*$)', line)
                if serial:
                    active_displays[current_key]["serial"] = serial.group(2)
                model = re.match(r'^\s*(Model:)', line)
                if model:
                    active_displays[current_key]["model"] = " ".join(line.split()[1:])
        return active_displays


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Control ThinkPad keyboard backlight.")
    parser.add_argument(
        "value",
        type=int,
        help="Dual monitor increment value to set"
    )
    args = parser.parse_args()
    DualMonitorBrightness().increment(args.value)
