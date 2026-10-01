autoload -Uz compinit
compinit

autoload -Uz colors && colors
autoload -Uz add-zsh-hook

# --------------------------------------------------
# Prompt
# --------------------------------------------------


git_prompt_info() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) ||
        branch=$(git rev-parse --short HEAD 2>/dev/null) ||
        return

    local dirty=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        dirty=" %{$fg_bold[yellow]%}✗"
    fi

    echo " %{$fg_bold[blue]%}git:(%{$fg[red]%}${branch}%{$fg_bold[blue]%})${dirty}%{$reset_color%}"
}

set_prompt() {
    local exit_code=$?
    local git_info
    local arrow

    git_info="$(git_prompt_info)"
    arrow="%{$fg_bold[green]%}➜"

    # CHANGED %c to %~ below to show the full path
    PROMPT="${arrow}  %{$fg_bold[cyan]%}%~%{$reset_color%}${git_info} "

    if [[ -n "$VIRTUAL_ENV_PROMPT" ]]; then
        PROMPT="${VIRTUAL_ENV_PROMPT} ${PROMPT}"
    fi
}


add-zsh-hook precmd set_prompt

# --------------------------------------------------
# Functions
# --------------------------------------------------

pipthis() {
    pip install . --no-deps --trusted-host jfrog.nts.ops
}

# --------------------------------------------------
# Aliases
# --------------------------------------------------

alias ls='ls -G'
alias ll='ls -alFG'
alias la='ls -AG'
alias l='ls -CFlG'

# --------------------------------------------------
# Secrets
# --------------------------------------------------

if [[ -f "${HOME}/.secrets.sh" ]]; then
    source "${HOME}/.secrets.sh"
fi

# --------------------------------------------------
# Neovim
# --------------------------------------------------

export NVIM_APPNAME="nvim_minimal"

# --------------------------------------------------
# venvman
# --------------------------------------------------

VENVMAN_ROOT_DIR="${HOME}/.venvman"
if [[ -d ${VENVMAN_ROOT_DIR} ]]; then
    source "${HOME}/.venvman/venvman/src/main.sh"
fi

# --------------------------------------------------
# PATH
# --------------------------------------------------

PATH="${HOME}/miniforge3/bin:${PATH}"
PATH="${HOME}/.local/src/nvm/versions/node/v22.14.0/bin:${PATH}"
PATH="${HOME}/.local/bin:${PATH}"

# --------------------------------------------------
# NVM
# --------------------------------------------------


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --------------------------------------------------
# System Python virtual environment
# --------------------------------------------------

if python3.12 --version >/dev/null 2>&1; then
    SYS_VENV="${HOME}/.sysvenv/venv"
    export PATH="${SYS_VENV}/bin:${PATH}"

    if python3.12 -m venv --help >/dev/null 2>&1; then
        if [[ ! -f "${SYS_VENV}/bin/activate" ]]; then
            python3.12 -m venv "${SYS_VENV}"
        fi

        source "${SYS_VENV}/bin/activate"
    fi

fi

# --------------------------------------------------
# Completion
# --------------------------------------------------

_pip_completion() {
    COMPREPLY=($(
        COMP_WORDS="${COMP_WORDS[*]}" \
            COMP_CWORD=$COMP_CWORD \
            PIP_AUTO_COMPLETE=1 \
            "$1" 2>/dev/null
    ))
}

complete -o default -F _pip_completion pip 2>/dev/null

eval "$(register-python-argcomplete serverctl)"
eval "$(register-python-argcomplete monocommit)"
source /Users/eisenbnt/.venvman/venvman/src/main.sh
