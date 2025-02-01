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

function in_path() {
    if [[ ":$PATH:" == *":$1:"* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

MY_BIN_DIR="$HOME/.local/nicholas/bin"
export PATH=$PATH:"$MY_BIN_DIR:"

function setup_my_bin() {
    local MY_BIN_DIR="$HOME/.local/nicholas/bin"
    local SUCCESS

    if [[ ! -d "$MY_BIN_DIR" ]]; then
        echo "$MY_BIN_DIR does not exit."
        read -p "Should I create it and add it to PATH? [y/N]" response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            mkdir -p $MY_BIN_DIR
            if [[ -d $MY_BIN_DIR ]]; then
                echo "$MY_BIN_DIR has been created"
                SUCCESS="true"
            else
                echo "FAIL: $MY_BIN_DIR has not been created"
                SUCCESS="false"
            fi

            export PATH=$PATH:$MY_BIN_DIR
            if [[ $(in_path MY_BIN_DIR)=="true" ]]; then
                echo "$MY_BIN_DIR has been added to path"
                SUCCESS="true"
            else
                echo "FAIL: $MY_BIN_DIR has not been added to path"
                SUCCESS="false"
            fi
        fi
    else
        if [[ $(in_path "$MY_BIN_DIR") == "false" ]]; then
            echo "$MY_BIN_DIR is not in PATH."
            read -p "Should I add it to PATH? [y/N]" response

            if [[ "$response" =~ ^[Yy]$ ]]; then
                export PATH=$PATH:$MY_BIN_DIR
            fi

            if [[ $(in_path MY_BIN_DIR) == "true" ]]; then
                echo "$MY_BIN_DIR has been added to path"
                SUCCESS="true"
            else
                echo "FAIL: $MY_BIN_DIR has not been added to path"
                SUCCESS="false"
            fi
        else
            SUCCESS="true"
        fi
    fi
    echo $SUCCESS
}

function sym_link_to_my_bin() {
    local MY_BIN_DIR="$HOME/.local/nicholas/bin"
    
    local SUCCESS=$(setup_my_bin)

    if [[ -f $1 && $SUCCESS != "false" ]]; then
        local BASENAME=$(basename $1)
        local FILENAME="${BASENAME%%.*}"
        chmod +x $1
        if [[ ! -L "$MY_BIN_DIR/$FILENAME" ]]; then
            echo "Attempting to symlink $1 to $MY_BIN_DIR/$FILENAME." 
            read -p "Do you want to continue [y/N]: " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                ln -s $1 "$MY_BIN_DIR/$FILENAME"
                echo "The link "$MY_BIN_DIR/$FILENAME" has been created"
            else
                echo "Link skipped"
            fi
        fi
    else
        echo "$1 is not a file" 
        echo $SUCCESS
    fi
}

if [[ -d "$HOME/software" ]]; then
    source_file "$HOME/software/venv_manager/src/venv.sh"
    source_file "$HOME/software/tmux_ide/ide.sh"
    sym_link_to_my_bin "$HOME/software/timer/timer.py"
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
