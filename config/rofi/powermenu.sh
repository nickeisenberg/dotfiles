#!/usr/bin/env bash

if [[ $XDG_SESSION_TYPE == "wayland" ]]; then
    source ${HOME}/.bash_profile
fi

$HOME/.config/rofi/scripts/powermenu_t1
