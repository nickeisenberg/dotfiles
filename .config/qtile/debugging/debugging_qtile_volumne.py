from os import system
clear = lambda : system('clear')
import libqtile.widget.volume as vol
import subprocess

# Get the volume percent
cmd = 'amixer -D pulse get Master | awk -F \'Left:|[][]\' \'BEGIN {RS=\"\"}{ print $3 }\''

subprocess.getoutput(cmd)

cmd = [
    'amixer',
    '-D',
    'pulse',
    'get',
    'Master',
]

subprocess.check_output(
    cmd, encoding="utf-8"
)

v = vol.Volume(get_volume_command=cmd)

subprocess.check_output(
    v.create_amixer_command(), encoding="utf-8"
)

v.get_volume()



# figure out the check mute command

check_mute_command = 'pacmd list-sinks | grep -q \"muted: yes\"; echo $?'
subprocess.getoutput(check_mute_command)

v = vol.Volume(
    get_volume_command=cmd,
    check_mute_command=check_mute_command,
    check_mute_string="0"
)

check_mute = subprocess.getoutput(v.check_mute_command)
check_mute in v.check_mute_string

v.get_volume()


