source $HOME/.bashrc

function get_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if git --version > /dev/null 2>&1; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(get_git_branch)\[\033[00m\]\$ '
else
    PS1='$\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]\[\033[00m\]\$ '
fi

alias ll='ls -alF --group-directories-first'
alias l='ls -l --group-directories-first'

export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.local/src/brew/bin:${PATH}"

# default sys venv
if [[ ! -f "${HOME}/.venv/bin/activate" ]]; then
    if python3.11 -m venv --help > /dev/null 2>&1; then
        python3.11 -m venv "${HOME}/.venv"
    fi
fi
source "${HOME}/.venv/bin/activate" > /dev/null 2>&1
