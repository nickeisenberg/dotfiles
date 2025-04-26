source $HOME/.bashrc

export PATH="${HOME}/.local/bin:${PATH}"

alias c="clear"
alias ll='ls -alF --group-directories-first'
alias l='ls -l --group-directories-first'

function get_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

color_prompt=yes
if [ "$color_prompt" = yes ]; then
    if git --version > /dev/null 2>&1; then
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(get_git_branch)\[\033[00m\]\$ '
    else
        PS1='$\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]\[\033[00m\]\$ '
    fi
else
    PS1='\u@\h:\w$(get_git_branch)\$ '
fi

# default sys venv
if [[ ! -f "${HOME}/.venv/bin/activate" ]]; then
    if python3.11 -m venv --help > /dev/null 2>&1; then
        python3.11 -m venv "${HOME}/.venv"
    fi
fi
source "${HOME}/.venv/bin/activate" > /dev/null 2>&1
