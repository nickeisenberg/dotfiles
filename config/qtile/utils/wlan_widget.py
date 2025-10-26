import subprocess

try:
    import iwlib

except ImportError:
    try:
        _ = subprocess.run(["iw", "--help"], stdout=subprocess.DEVNULL)

    except FileNotFoundError as e:
        raise e

from libqtile.log_utils import logger
from libqtile.pangocffi import markup_escape_text
from libqtile.widget import base


def get_status(interface_name: str):
    """Return ESSID and signal strength (0–100%) using `iw`, scaled linearly from -100 to -30 dBm."""
    try:
        result = subprocess.run(
            ["iw", "dev", interface_name, "link"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.exception(f"Could not get wifi status for {interface_name}:")
        return None, None

    output = result.stdout
    if "Not connected." in output:
        return None, None

    essid, signal_dbm = None, None
    for line in output.splitlines():
        line = line.strip()
        if line.startswith("SSID:"):
            essid = line.split("SSID:")[1].strip()
        elif line.startswith("signal:"):
            signal_dbm = int(line.split()[1])

    if essid is None or signal_dbm is None:
        return None, None

    return essid, signal_dbm


def get_private_ip(interface_name: str):
    """Return IPv4 address using `ip`."""
    try:
        result = subprocess.run(
            ["ip", "-brief", "addr", "show", "dev", interface_name],
            capture_output=True,
            text=True,
            check=True,
        )

    except (subprocess.CalledProcessError, OSError):
        logger.exception(f"Couldn't get the IP for {interface_name}:")
        return "N/A"

    output = result.stdout.strip().split()
    if len(output) >= 3 and output[1] == "UP":
        ip = output[2].split("/")[0]
        if ":" not in ip:
            return ip

    return "N/A"


class Wlan(base.InLoopPollText):
    """
    Displays Wifi SSID and quality using `iw` (no iwlib dependency).
    """

    orientations = base.ORIENTATION_HORIZONTAL
    defaults = [
        ("interface", "wlan0", "The interface to monitor"),
        ("ethernet_interface", "eth0", "Ethernet interface to monitor"),
        ("update_interval", 1, "Update interval."),
        ("disconnected_message", "Disconnected", "String when wifi is down."),
        ("ethernet_message_format", "eth", "Message when ethernet is used."),
        ("use_ethernet", False, "Check ethernet when wifi disconnected."),
        ("format", "{essid} {quality}/70", "Display format."),
    ]

    def __init__(self, **config):
        base.InLoopPollText.__init__(self, **config)
        self.add_defaults(Wlan.defaults)
        self.ethernetInterfaceNotFound = False

    def poll(self):
        try:
            essid, quality = get_status(self.interface)
            if quality is not None:
                quality *= -1

            disconnected = essid is None
            ipaddr = "N/A"

            if not disconnected:
                ipaddr = get_private_ip(self.interface)
            else:
                if self.use_ethernet:
                    ipaddr = get_private_ip(self.ethernet_interface)

                    try:
                        with open(
                            f"/sys/class/net/{self.ethernet_interface}/operstate"
                        ) as statfile:
                            if statfile.read().strip() == "up":
                                return self.ethernet_message_format.format(
                                    ipaddr=ipaddr
                                )
                            else:
                                return self.disconnected_message
                    except FileNotFoundError:
                        if not self.ethernetInterfaceNotFound:
                            logger.error("Ethernet interface not found!")
                            self.ethernetInterfaceNotFound = True
                        return self.disconnected_message
                else:
                    return self.disconnected_message

            return self.format.format(
                essid=markup_escape_text(essid),
                quality=quality if quality is not None else "N/A",
                percent=quality / 70 if quality is not None else "N/A",
                ipaddr=ipaddr,
            )

        except OSError:
            logger.error("Your wlan device is likely off or not present.")
            return self.disconnected_message


if __name__ == "__main__":
    get_status("wlp0s20f3")
    get_private_ip("wlp0s20f3")
