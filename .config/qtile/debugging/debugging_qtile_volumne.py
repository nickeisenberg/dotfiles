from os import system
clear = lambda : system('clear')
import libqtile.widget.volume as vol
import subprocess


cmd = 'amixer -D pulse get Master | awk -F \'Left:|[][]\' \'BEGIN {RS=\"\"}{ print $3 }\''

v = vol.Volume(get_volume_command=cmd)

v.get_volume()

subprocess.getoutput(cmd)

