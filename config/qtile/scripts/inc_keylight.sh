# #! /bin/bash
# 
# # Inside /etc/sudoers.d I have to add a file called `inc_keylight` and inside
# # this file I added the following line:
# # nicholas ALL=(ALL:ALL) NOPASSWD: /home/nicholas/Dotfiles/.config/qtile/scripts/_inc_keylight.sh
# # The name of the file in /etc/sudoers.d in not important as all files in that dir are
# # imported. This removes the need for a sudo password to change values inside the 
# # keylight brightness folder. I did the same for the dec_keylight function as well.
# 
# 
# function increase_keylight() {
#     
#     current=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness)
# 
#     new=$(echo $current + 1 | bc)
# 
#     if [ "$new" -gt 2 ]
#         then
#             ((new-=1))
#     fi
# 
#     echo $new | tee /sys/class/leds/tpacpi::kbd_backlight/brightness > /dev/null
# 
# }  


#!/bin/bash

# Define common backlight control paths

increase_brightness() {
    # Define common backlight control paths
    declare -a paths=(
        "/sys/class/leds/tpacpi::kbd_backlight/brightness" # Path for ThinkPad
        "/sys/class/leds/system76_acpi::kbd_backlight/brightness" # Path for System76
        # Add more paths as needed
    )

    local current
    local new
    local max
    local pathFound=false

    for path in "${paths[@]}"; do
        if [ -e "$path" ]; then
            current=$(cat "$path")
            max=$(cat "${path%/*}/max_brightness")
            new=$((current + 1))

            if [ "$new" -gt "$max" ]; then
                new=0 # Loop back to 0 or set to max if you don't want cycling
            fi

            echo $new | sudo tee "$path" > /dev/null
            pathFound=true
            break # Exit the loop once the first existing path is found and adjusted
        fi
    done

    if [ "$pathFound" = false ]; then
        echo "Compatible keyboard backlight control not found."
        return 1
    fi
}

increase_keylight
