#!/bin/sh

# capslock to control
setxkbmap -option ctrl:nocaps &

picom --experimental-backends --backend glx --xrender-sync-fence &
