# Enable bash completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Git branch parsing function
parse_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -n $branch ]] && echo " ($branch)"
}

# Set prompt function
set_prompt() {
    FANCY=false

    local PROMPT_NO_STATUS="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\W\[\e[1;31m\]$(parse_git_branch)\[\e[0m\] \$ "
    local PROMPT_STATUS="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\W\[\e[1;31m\]$(parse_git_branch)\[\e[0m\] (x) \$ "

    if $FANCY; then
        STATUS=$(git status --short 2> /dev/null)
    fi

    if [ -n "$STATUS" ]; then
        PS1=$PROMPT_STATUS
    else
        PS1=$PROMPT_NO_STATUS
    fi

    if [ -n "$VIRTUAL_ENV_PROMPT" ]; then
        PS1="${VIRTUAL_ENV_PROMPT} ${PS1}"
    fi
}

# pipthis function
pipthis() {
    pip install . --no-deps --trusted-host jfrog.nts.ops
}

# Set prompt command to run before each prompt
PROMPT_COMMAND=set_prompt

#--------------------------------------------------
# Alias
#--------------------------------------------------
alias ls='ls -G'
alias ll='ls -alFG'
alias la='ls -AG'
alias l='ls -CFlG'
#--------------------------------------------------

# Source secrets if exists
if [[ -f "${HOME}/.secrets.sh" ]]; then
    source "${HOME}/.secrets.sh"
fi

export NVIM_APPNAME="nvim_minimal"

VENVMAN_ROOT_DIR=$HOME/.venvman
source "$HOME/.venvman/venvman/src/main.sh"

#--------------------------------------------------

PATH="${HOME}/.local/src/miniconda3/bin:${PATH}"
PATH="${HOME}/.local/src/nvm/versions/node/v22.14.0/bin:${PATH}"
PATH="/Library/Frameworks/Python.framework/Versions/3.11/bin:${PATH}"
PATH="${HOME}/.local/bin:${PATH}"

# nvm lazy loading function
nvm() {
    unset -f nvm
    export NVM_DIR="$HOME/.local/src/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    nvm "$@"
}

# Python virtual environment setup
if python3.12 --version > /dev/null 2>&1; then
    SYS_VENV="${HOME}/.sysvenv/venv"
    if python3.12 -m venv --help > /dev/null 2>&1; then
        if [[ -f "${SYS_VENV}/bin/activate" ]]; then
# source "${SYS_VENV}/bin/activate"  # commented out by conda initialize
        else
            python3.12 -m venv ${SYS_VENV}
# source "${SYS_VENV}/bin/activate"  # commented out by conda initialize
        fi
    fi
    export PATH="${SYS_VENV}/bin/:${PATH}"
fi

# pip completion
_pip_completion() {
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   PIP_AUTO_COMPLETE=1 $1 2>/dev/null ) )
}
complete -o default -F _pip_completion pip 2>/dev/null

# Python argcomplete registrations
eval "$(register-python-argcomplete serverctl)"
eval "$(register-python-argcomplete monocommit)"

