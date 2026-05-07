source $HOME/.bashrc


lustre() {
	which=$1
	if [[ ! -z $2 ]]; then
		where=$2
	else
		where=eisenbnt
	fi
	cd /p/lustre${which}/${where}
}

get_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if git --version > /dev/null 2>&1; then
    export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(get_git_branch)\[\033[00m\]\n\$ '

else
    export PS1='$\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]\[\033[00m\]\$ '
fi

if [[ -f "${HOME}/.secrets.sh" ]]; then
	    source "${HOME}/.secrets.sh"
fi

alias ll='ls -alF --group-directories-first'
alias l='ls -l --group-directories-first'


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="${HOME}/.local/bin:${PATH}"

if [[ -f "${HOME}/.secrets.sh" ]]; then
	    source "${HOME}/.secrets.sh"
fi

# brew shit
eval "$(/usr/workspace/${USER}/.local/src/brew/bin/brew shellenv)"

# default sys venv
if [[ ! -f "${HOME}/.venv/bin/activate" ]]; then
    if python3.11 -m venv --help > /dev/null 2>&1; then
        python3.11 -m venv "${HOME}/.venv"
    fi
fi
source "${HOME}/.venv/bin/activate" > /dev/null 2>&1
export VENVMAN_ROOT_DIR=/usr/workspace/eisenbnt/.venvman
source /usr/workspace/eisenbnt/.venvman/venvman/src/main.sh
