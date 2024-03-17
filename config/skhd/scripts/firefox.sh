#!/bin/bash

# Check if Firefox is not running
if ! pgrep -x "Firefox" > /dev/null; then
    # If Firefox is not running, start it on the current desktop
    open -na "Firefox" --args --new-window
else
    # If Firefox is running, open a new window on the current desktop
    osascript -e 'tell application "Firefox" to activate'
    osascript -e 'tell application "System Events" to tell process "Firefox" to keystroke "n" using {command down}'
fi

