#! /bin/bash

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
