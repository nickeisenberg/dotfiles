import subprocess
import threading
from libqtile import widget, qtile

class NetworkStatus(widget.TextBox):
    def __init__(self, update_interval=5, **config):
        super().__init__(**config)
        self.update_interval = update_interval
        self.update_status()
        self.update_timer = threading.Timer(self.update_interval, self.update_status)
        self.update_timer.start()
        self.add_callbacks({"Button1": self.open_nmtui})

    def _check_connection(self):
        result = subprocess.run(['nmcli', '-t', '-f', 'STATE', 'g'], capture_output=True, text=True)
        return result.stdout.strip() == 'connected'

    def update_status(self):
        if self._check_connection():
            self.text = ' '
        else:
            self.text = '\uf6ac'
        self.draw()
        # Restart the timer for the next update
        self.update_timer = threading.Timer(self.update_interval, self.update_status)
        self.update_timer.start()

    def open_nmtui(self):
        # Replace 'x-terminal-emulator' with your preferred terminal emulator
        subprocess.Popen(['alacritty', '-e', 'nmtui'])

    def finalize(self):
        self.update_timer.cancel()
        super().finalize()


