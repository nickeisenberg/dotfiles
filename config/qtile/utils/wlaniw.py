import re
from libqtile.log_utils import logger
from libqtile.widget.generic_poll_text import GenPollCommand

def parse_iw_output(raw: str):
    essid, quality = None, None
    for line in raw.splitlines():
        line = line.strip()

        if line.startswith("SSID:"):
            essid_match = re.search(r"SSID:\s*(.*)", line)
            if essid_match:
                essid = essid_match.group(1)

        elif line.startswith("signal:"):
            signal_match = re.search(r"signal:\s*(-?\d+)", line)
            if signal_match:
                signal = int(signal_match.group(1))
                # see: https://superuser.com/questions/866005/wireless-connection-link-quality-what-does-31-70-indicate
                quality = signal + 110

    if essid is None:
        logger.exception("SSID could not be determined from iw")

    if quality is None:
        logger.exception("signal could not be determined from iw")

    return f"{essid} {round(quality/70*100)}%"

class WlanIw(GenPollCommand):
    defaults = []
    
    def __init__(self, **config):
        config["cmd"] = ["iw", "dev", "wlp0s20f3", "link"]
        GenPollCommand.__init__(self, **config)
        self.add_defaults(WlanIw.defaults)

    def parse(self, raw: str):
        return parse_iw_output(raw)

