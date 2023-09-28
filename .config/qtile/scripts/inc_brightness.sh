#!/bin/bash

inc_bright(){

    local val=$(xrandr --verbose | awk '/Bright/ {print $2}')
    local inv_val=.1
    local newval=$(echo "$val + $inv_val" | bc);
    xrandr --output eDP-1 --brightness $newval;

}

inc_bright

