from os import system
clear = lambda : system('clear')
import libqtile.widget.volume as vol
import subprocess

cmd = [
'amixer', '-D', 'pulse', 'get', 'Master',
]
subprocess.check_output(cmd)

v = vol.Volume(
    get_volume_command=cmd,
)

v.get_volume()

v.volume
