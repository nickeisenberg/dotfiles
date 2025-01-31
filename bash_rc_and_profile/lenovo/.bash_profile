source ~/.bashrc
source ~/.credentials/password.sh
source ~/.credentials/keypairs/paths.sh

export EDITOR='nvim'

#--------------------------------------------------
# Load the gitbranch in the PS1
#--------------------------------------------------
parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi
#--------------------------------------------------

# key press delay time 
xset r rate 250 30

# spicetify path
export PATH=$PATH:/home/nicholas/.spicetify

# cuda paths
export PATH="/usr/local/cuda-12.1/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.1/lib64:$LD_LIBRARY_PATH"

# spicetify stuff
export PATH=$PATH:/home/nicholas/.spicetify
. "$HOME/.cargo/env"

# nvm paths
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# qtile path
export PATH="$HOME/.local/bin:$PATH"

# sudo edit env variables
export SUDO_EDITOR="nvim"

function source_file() {
    if [[ -f $1 ]]; then
        source $1
    else
        echo "$1 is not a file" 
    fi
}

function sym_link_to_bin() {
    if [[ -f $1 ]]; then
        local BASENAME=$(basename $1)
        local FILENAME="${BASENAME%%.*}"
        chmod +x $1
        if [[ -d "$HOME/.local/bin" ]]; then
            if [[ ! -L "$HOME/.local/bin/$FILENAME" ]]; then
                read -p "Attempting to symlink $1 to $HOME/.local/bin. Do you want to continue '$1'? [y/N]: " response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    sudo ln -s $1 "$HOME/.local/bin/$FILENAME"
                    echo "The link "$HOME/.local/bin/$FILENAME" has been created"
                else
                    echo "Link skipped"
                fi
            fi
        fi
    else
        echo "$1 is not a file" 
    fi
}

if [[ -d "$HOME/software" ]]; then
    source_file "$HOME/software/venv_manager/src/venv.sh"
    source_file "$HOME/software/tmux_ide/ide.sh"
    sym_link_to_bin "$HOME/software/timer/timer.py"
fi

# some aliases
alias ipython='python3 -m IPython'
alias python='python3'


#--------------------------------------------------
# source all scripts
#--------------------------------------------------
for file in $HOME/dotfiles/scripts/*; do
    source $file
done
