#!/bin/bash

# Check if iTerm is running
if pgrep "iTerm" > /dev/null; then
    # If iTerm is running, create a new window
    osascript -e 'tell application "iTerm" to create window with default profile'
else
    # If iTerm is not running, just open iTerm
    open -a iTerm
fi
