#!/bin/bash

# to get this to work with no sudo password, I added
# `nicholas ALL=(ALL) NOPASSWD: /usr/bin/light` in to the file
# /etc/sudoers.d/sudo_no_password

dec_bright(){
    sudo light -U 10
};

dec_bright
