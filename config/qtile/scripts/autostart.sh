#!/usr/bin/env bash

#----------
# capslock to control
#----------
setxkbmap -option ctrl:nocaps &

# picom --experimental-backends --backend glx --xrender-sync-fence &

#----------
# Wallpaper
#----------

# rosepint
# xsetroot -solid '#191724'

# vague
xsetroot -solid '#141415'

# nvim default
# xsetroot -solid "#14161b"
#----------

${HOME}/.config/qtile/scripts/battery-check &

# natural scrolling
xinput set-prop 11 "libinput Natural Scrolling Enabled" 1

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
