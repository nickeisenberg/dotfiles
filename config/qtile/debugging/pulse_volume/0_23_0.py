from libqtile.widget import pulse_volume

get_volume_command = 'amixer -D pulse get Master | awk -F \'Left:|[][]\' \'BEGIN {RS=\"\"}{ print $3 }\''
check_mute_command = 'pacmd list-sinks | grep -q \"muted: yes\"; echo $?'
check_mute_command_string = '0'

pv = pulse_volume.PulseVolume(
    get_volume_command=get_volume_command,
    check_mute_command=check_mute_command,
    check_mute_command_string=check_mute_command_string
)

pv.update()

pv.get_volume()

