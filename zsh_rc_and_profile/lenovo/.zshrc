# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
add_to_path /usr/local/bin 0
add_to_path $HOME/.local/bin 0
add_to_path $HOME/bin 0


# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

if [[ ! -d $ZSH ]]; then
    echo "~/.oh-my-zsh is not found. Cloning now."
    git clone https://github.com/ohmyzsh/ohmyzsh.git $ZSH
fi

# See $HOME/.oh-my-zsh/themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

zstyle ':omz:update' mode disabled  # disable automatic updates

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Standard plugins can be found in $ZSH/plugins/
plugins=(git)

source $ZSH/oh-my-zsh.sh

#--------------------------------------------------
# Alias
#--------------------------------------------------
alias ipython='python3 -m IPython'
alias python='python3'
alias ll='ls -alF --group-directories-first'
alias la='ls -A --group-directories-first'
alias l='ls -CFl --group-directories-first'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
#--------------------------------------------------


#--------------------------------------------------
# Settings
#--------------------------------------------------
xset r rate 250 30  # key press delay time 
#--------------------------------------------------

#--------------------------------------------------
# PATHS
#--------------------------------------------------

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi


export EDITOR='nvim'
export SUDO_EDITOR="nvim"
export PATH="$HOME/.local/bin:$PATH"

# spicetify path
export PATH=$PATH:/home/nicholas/.spicetify


# cuda paths
export PATH="/usr/local/cuda-12.1/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.1/lib64:$LD_LIBRARY_PATH"


# spicetify stuff
export PATH=$PATH:/home/nicholas/.spicetify
. "$HOME/.cargo/env"


#--------------------------------------------------



# From helpers.sh
if [[ -d "$HOME/software" ]]; then
    create_directory_and_add_to_path "$HOME/.local/nicholas/bin" 1
    sym_link_file_as_bin "$HOME/software/timer/timer.py" "$HOME/.local/nicholas/bin"

    source_file "$HOME/.venvman/venvman/src/venvman.sh"
    source_file "$HOME/.venvman/venvman/src/completion/completion.sh"
    source_file "$HOME/software/tmux_ide/ide.sh"
fi
#--------------------------------------------------
