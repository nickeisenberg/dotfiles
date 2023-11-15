#!/bin/bash

alacritty -e bash -i -c "cd $HOME/.config/qtile && source $HOME/.bash_profile && nvim $HOME/.config/qtile/config.py"

