#!/bin/bash

dec_bright(){
    local val=$(xrandr --verbose | awk '/Bright/ {print $2}')
    local inv_val=-.05
    
    echo $val;
    echo $inv_val;
    
    local newval=$(echo "$val + $inv_val" | bc);
    
    echo $newval;
    
    xrandr --output eDP-1 --brightness $newval
};

dec_bright
