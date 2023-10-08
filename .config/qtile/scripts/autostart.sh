#!/bin/sh

# capslock to control
setxkbmap -option ctrl:nocaps &

picom --experimental-backends --backend glx --xrender-sync-fence &

# set up the dual monitor
# Use xrandr --verbose to ge the monitor names
sleep 1
xrandr --output HDMI-1-0 --noprimary --above eDP-1
