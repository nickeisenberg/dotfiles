#!/bin/sh

# capslock to control
setxkbmap -option ctrl:nocaps &

# picom --experimental-backends --backend glx --xrender-sync-fence &

feh --bg-scale ~/dots_ubuntu/config/qtile/rosepine.png

# set up the dual monitor
# Use xrandr --verbose to ge the monitor names
sleep 1

var=$(xrandr | awk '/HDMI-1-0/ {print $2}')
if [ "$var" = "connected" ];
    then
        xrandr --output HDMI-1-0 --noprimary --above eDP-1
fi
