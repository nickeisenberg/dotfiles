#! /bin/bash

# to get this to work with no sudo password, I added
# nicholas ALL=(ALL:ALL) NOPASSWD: /home/nicholas/Dotfiles/.config/qtile/scripts/inc_keylight.sh
# /etc/sudoers.d/sudo_no_password

function increase_keylight() {
    
    current=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness)

    new=$(echo $current + 1 | bc)

    if [ "$new" -gt 2 ]
        then
            ((new-=1))
    fi

    echo $new | tee /sys/class/leds/tpacpi::kbd_backlight/brightness > /dev/null

}  

increase_keylight
