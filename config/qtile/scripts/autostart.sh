#!/bin/sh

#----------
# capslock to control
#----------
setxkbmap -option ctrl:nocaps &

# picom --experimental-backends --backend glx --xrender-sync-fence &

#----------
# Wallpaper
#----------
xsetroot -solid '#191724'
# feh --bg-scale $HOME/Downloads/wall-02.webp
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
