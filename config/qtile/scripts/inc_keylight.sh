#! /bin/bash

# to get this to work with no sudo password, I added
# nicholas ALL=(ALL:ALL) NOPASSWD: /home/nicholas/Dotfiles/.config/qtile/scripts/inc_keylight.sh
# /etc/sudoers.d/sudo_no_password


increase_keylight() {
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
                new=$current # Loop back to 0 or set to max if you don't want cycling
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
