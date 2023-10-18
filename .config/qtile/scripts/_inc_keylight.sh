#! /bin/bash

# Inside /etc/sudoers.d I have to add a file called `inc_keylight` and inside
# this file I added the following line:
# nicholas ALL=(ALL:ALL) NOPASSWD: /home/nicholas/Dotfiles/.config/qtile/scripts/_inc_keylight.sh
# The name of the file in /etc/sudoers.d in not important as all files in that dir are
# imported. This removes the need for a sudo password to change values inside the 
# keylight brightness folder. I did the same for the dec_keylight function as well.


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
