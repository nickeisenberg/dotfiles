#!/bin/bash

# to get this to work with no sudo password, I added
# `nicholas ALL=(ALL) NOPASSWD: /usr/bin/light` in to the file
# /etc/sudoers.d/sudo_no_password

inc_bright(){
    sudo light -A 10
};

inc_bright
