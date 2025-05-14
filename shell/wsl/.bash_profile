source "${HOME}/.bashrc"
source "${HOME}/dotfiles/scripts/helpers.sh"

if [[ -d "${HOME}/.credentials" ]]; then
    for file in $(ls "${HOME}/.credentials"); do
        source "${HOME}/.credentials/$file"
    done
fi

alias ll='ls -alF --group-directories-first'
alias l='ls -l --group-directories-first'

# From helpers.sh
color_prompt=yes
if [ "$color_prompt" = yes ]; then
    if git --version > /dev/null 2>&1 ; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(get_git_branch)\[\033[00m\]\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]\[\033[00m\]\$ '
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi
#--------------------------------------------------

export PATH="${HOME}/.local/bin:$PATH"

# cuda paths
export PATH="/usr/local/cuda-12.6/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH"

# nvm paths
export NVM_DIR="$HOME/.local/src/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#--------------------------------------------------

if [[ -f "${HOME}/.venvman/venvman/src/main.sh" ]]; then
	source "${HOME}/.venvman/venvman/src/main.sh"
fi

export PATH="${HOME}/.sysvenv/bin:$PATH"

if python3.11 --version > /dev/null; then
	if python3.11 -m venv --help > /dev/null; then
		if [[ -f "${HOME}/.sysvenv/bin/activate" ]]; then
			source "${HOME}/.sysvenv/bin/activate"
		else
			python3.11 -m venv "${HOME}/.sysvenv"
			source "${HOME}/.sysvenv/bin/activate"
		fi
	fi
fi

