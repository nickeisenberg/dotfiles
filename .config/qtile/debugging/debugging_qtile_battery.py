from os import system
clear = lambda : system('clear')
import libqtile.widget.battery as bat

# this correctly loads the system
import platform
platform.system()

# Linux battery class seems to work except. There is not "Not charging" status
# though
l = bat._LinuxBattery()

l._load_file('energy')

l._get_param('status_file')

l.update_status()

# loads the linux battery
bat.load_battery()

# test the Battery class
b = bat.Battery()

b._battery

b.poll()

status = b._battery.update_status()

status.state
status.time
status.percent

b.build_string(status)


b._battery._get_battery_name()

