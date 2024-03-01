#!/bin/sh

#----------
# capslock to control
#----------
setxkbmap -option ctrl:nocaps &

# picom --experimental-backends --backend glx --xrender-sync-fence &

#----------
# Wallpaper
#----------
# feh --bg-scale ~/dots_ubuntu/config/qtile/rosepine.png
xsetroot -solid '#191724'
#----------

python3 ~/.config/qtile/scripts/battery_check.py &

#----------
# set up the dual monitor
# Use xrandr --verbose to ge the monitor names
#----------
sleep 1

var=$(xrandr | awk '/HDMI-1-0/ {print $2}')
if [ "$var" = "connected" ];
    then
        xrandr --output HDMI-1-0 --noprimary --above eDP-1
fi
