from os import system
clear = lambda : system('clear')
import libqtile.widget.volume as vol
import subprocess
import re


# Get the volume percent
cmd = 'amixer -D pulse get Master | awk -F \'Left:|[][]\' \'BEGIN {RS=\"\"}{ print $3 }\''
mixer_out = subprocess.getoutput(cmd)
re_vol = re.compile(r"(\d?\d?\d?)%")
volgroups = re_vol.search(mixer_out)
int(volgroups.groups()[0])


# figure out the check mute command
check_mute_command = 'pacmd list-sinks | grep -q \"muted: yes\"; echo $?'
subprocess.getoutput(check_mute_command)

cmd = 'amixer -D pulse get Master | awk -F \'Left:|[][]\' \'BEGIN {RS=\"\"}{ print $3 }\''
check_mute_command = 'pacmd list-sinks | grep -q \"muted: yes\"; echo $?'
check_mute_command_string = '0'
v = vol.Volume(
    get_volume_command=cmd,
    check_mute_command=check_mute_command,
    check_mute_string="0"
)


v.get_volume()

v._update_drawer()

v.update()
v.text


