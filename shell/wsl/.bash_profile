source "${HOME}/.bashrc"

get_git_branch() {
    if git --version > /dev/null; then
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
    else
        echo
    fi
}

if git --version > /dev/null 2>&1 ; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(get_git_branch)\[\033[00m\]\$ '
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]\[\033[00m\]\$ '
fi

alias ll='ls -alF --group-directories-first'
alias l='ls -l --group-directories-first'

export PATH="${HOME}/.local/bin:$PATH"

SUDO_EDITOR=$(which vi)
export SUDO_EDITOR

# cuda paths
export PATH="/usr/local/cuda-12.6/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH"

# nvm paths
export NVM_DIR="$HOME/.local/src/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PATH="${HOME}/.sysvenv/venv/bin/:${PATH}"
if python3.11 --version > /dev/null; then
	if python3.11 -m venv --help > /dev/null; then
		if [[ -f "${HOME}/.sysvenv/venv/bin/activate" ]]; then
			source "${HOME}/.sysvenv/venv/bin/activate"
		else
			python3.11 -m venv "${HOME}/.sysvenv/venv"
			source "${HOME}/.sysvenv/venv/bin/activate"
		fi
	fi
	export PATH="${HOME}/.sysvenv/venv/bin:$PATH"
fi


if [[ -f "${HOME}/.venvman/venvman/src/main.sh" ]]; then
	source "${HOME}/.venvman/venvman/src/main.sh"
fi
