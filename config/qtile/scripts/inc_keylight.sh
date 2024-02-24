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
    local increment
    local pathFound=false

    for path in "${paths[@]}"; do
        if [ -e "$path" ]; then
            current=$(cat "$path")
            max=$(cat "${path%/*}/max_brightness")

            # Check if 'system' is in the path and adjust the increment accordingly
            if [[ "$path" == *"system"* ]]; then
                increment=25
            else
                increment=1
            fi

            new=$((current + increment))

            # Ensure new value does not exceed max
            if [ "$new" -gt "$max" ]; then
                new=$max # Optionally, set to max or handle overflow differently
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
