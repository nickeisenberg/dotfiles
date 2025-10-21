source $HOME/.bashrc

#--------------------------------------------------
# Some helpers
#--------------------------------------------------
source $HOME/dotfiles/scripts/helpers.sh
source $HOME/dotfiles/scripts/clipboard.sh
#--------------------------------------------------

if [[ -f "${HOME}/.local/src/geant4/geant4-11.3/install/bin/geant4.sh" ]]; then
    source "${HOME}/.local/src/geant4/geant4-11.3/install/bin/geant4.sh"
fi

alias c="clear"
alias ll='ls -alF --group-directories-first'
alias l='ls -l --group-directories-first'

# From helpers.sh
color_prompt=yes
if [ "$color_prompt" = yes ]; then
    if is_on_system git; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(get_git_branch)\[\033[00m\]\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]\[\033[00m\]\$ '
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi
#--------------------------------------------------

#--------------------------------------------------
# Settings
#--------------------------------------------------
xset r rate 250 30  # key press delay time
setxkbmap -option ctrl:nocaps
#--------------------------------------------------

#--------------------------------------------------
# Alias
#--------------------------------------------------
alias ipython='python3 -m IPython'
alias python='python3'
#--------------------------------------------------

#--------------------------------------------------
# PATHS
#--------------------------------------------------
export PATH="${HOME}/.config/qtile/scripts:${PATH}"
export PATH="${HOME}/.venvman/envs/3.12/system/bin:${PATH}"

# cuda paths
export PATH="/usr/local/cuda-12.6/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH"

# nvm paths
export NVM_DIR="$HOME/.local/src/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#--------------------------------------------------

. "$HOME/.cargo/env"

# venvman
source ${HOME}/.venvman/venvman/src/main.sh

# default sys venv
if [[ ! -f "${HOME}/.sysvenv/venv/bin/activate" ]]; then
    if python3 -m venv --help > /dev/null 2>&1; then
        python3 -m venv "${HOME}/.sysvenv/venv"
    fi
fi
source "${HOME}/.sysvenv/venv/bin/activate" > /dev/null 2>&1




