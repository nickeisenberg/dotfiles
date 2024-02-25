#!/bin/bash

dec_dualbrightness(){

    local val=$(xrandr --verbose | awk '/Bright/ {print $2}' | tail -1)
    echo $val
    local inv_val=.1
    local newval=$(echo "$val + $inv_val" | bc);
    xrandr --output HDMI-1-0 --brightness $newval
};

dec_dualbrightness
