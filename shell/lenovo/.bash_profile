source $HOME/.bashrc

if xclip -h > /dev/null; then
    clipboard() {
        xclip -selection clipboard
    }
fi

get_git_branch() {
    if git --version > /dev/null; then
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
    else
        echo
    fi
}

color_prompt=yes
if [ "$color_prompt" = yes ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(get_git_branch)\[\033[00m\]\$ '
else
    PS1='\u@\h:\w$(get_git_branch)\$ '
fi
#--------------------------------------------------

#--------------------------------------------------
# Settings
#--------------------------------------------------
if [[ "${XDG_SESSION_TYPE}" == "x11" ]]; then
    xset r rate 250 30
    setxkbmap -option ctrl:nocaps
fi
#--------------------------------------------------

#--------------------------------------------------
# Alias
#--------------------------------------------------
alias ll='ls -alF --group-directories-first'
alias l='ls -l --group-directories-first'
alias ipython='python3 -m IPython'
alias python='python3'
#--------------------------------------------------

#--------------------------------------------------
# PATHS
#--------------------------------------------------
export PATH="${HOME}/.config/qtile/scripts:${PATH}"
export PATH="${HOME}/.venvman/envs/3.12/system/bin:${PATH}"

#--------------------------------------------------
# Software
#--------------------------------------------------

# cuda paths
export PATH="/usr/local/cuda-12.6/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH"

# nvm paths
export NVM_DIR="$HOME/.local/src/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#--------------------------------------------------

if [[ -f "${HOME}/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# venvman
if [[ -f "${HOME}/.venvman/venvman/src/main.sh" ]]; then
    source ${HOME}/.venvman/venvman/src/main.sh
fi

# geant
if [[ -f "${HOME}/.local/src/geant4/geant4-11.3/install/bin/geant4.sh" ]]; then
    source "${HOME}/.local/src/geant4/geant4-11.3/install/bin/geant4.sh"
fi

# default sys venv
if [[ ! -f "${HOME}/.sysvenv/venv/bin/activate" ]]; then
    if python3 -m venv --help > /dev/null 2>&1; then
        python3 -m venv "${HOME}/.sysvenv/venv"
    fi
fi
source "${HOME}/.sysvenv/venv/bin/activate" > /dev/null 2>&1
