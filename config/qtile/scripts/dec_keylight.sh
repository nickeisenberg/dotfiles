# #! /bin/bash
# 
# function decrease_keylight() {
#     
#     current=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness)
# 
#     new=$(echo $current - 1 | bc)
# 
#     if [ "$new" -lt 0 ]
#         then
#             ((new+=1))
#     fi
# 
#     sudo echo $new | tee /sys/class/leds/tpacpi::kbd_backlight/brightness > /dev/null
# 
# }  
# 
# decrease_keylight

decrease_brightness() {
    # Define common backlight control paths
    declare -a paths=(
        "/sys/class/leds/tpacpi::kbd_backlight/brightness" # Path for ThinkPad
        "/sys/class/leds/system76_acpi::kbd_backlight/brightness" # Path for System76
        # Add more paths as needed
    )

    local current
    local new
    local pathFound=false

    for path in "${paths[@]}"; do
        if [ -e "$path" ]; then
            current=$(cat "$path")
            new=$((current - 1))

            # Ensure new brightness level is not less than 0
            if [ "$new" -lt 0 ]; then
                new=0 # Keep at the lowest brightness level
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

decrease_keylight
