#!/bin/bash

adjust_keylight() {
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

            # Adjust the increment based on the system type
            if [[ "$path" == *"system"* ]]; then
                increment=25
            else
                increment=1
            fi

            case $1 in
                up)
                    new=$((current + increment))
                    # Ensure new value does not exceed max
                    if [ "$new" -gt "$max" ]; then
                        new=$max
                    fi
                    ;;
                down)
                    new=$((current - increment))
                    # Ensure new brightness level is not less than 0
                    if [ "$new" -lt 0 ]; then
                        new=0
                    fi
                    ;;
                *)
                    echo "Usage: ${0##*/} {up|down}"
                    return 1
                    ;;
            esac

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

adjust_keylight $1
