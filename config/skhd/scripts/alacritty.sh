#!/bin/bash

# Check if Alacritty is running
if pgrep "alacritty" > /dev/null; then
    # If Alacritty is running, you can send a command to open a new window.
    open -na Alacritty
else
    # If Alacritty is not running, just open Alacritty
    open -a Alacritty
fi
