#!/bin/bash

inc_bright(){

    local val=$(xrandr --verbose | grep 'Brightness' | awk '{print $2}' | head -1)
    local inv_val=.1
    local newval=$(echo "$val + $inv_val" | bc)
    
    # Ensure newval does not exceed 1.0
    if (( $(echo "$newval > 1.0" | bc -l) )); then
        newval=1.0
    fi

    xrandr --output eDP-1-1 --brightness $newval
}


inc_bright

