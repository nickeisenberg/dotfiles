#-------------------------------------------------- 
# Some helpers
#-------------------------------------------------- 
source $HOME/dotfiles/scripts/helpers.sh
source $HOME/dotfiles/scripts/dm.sh
#-------------------------------------------------- 

# from helpers.sh
add_to_path /usr/local/bin 0
add_to_path $HOME/.local/bin 0
add_to_path $HOME/bin 0

export ZSH="$HOME/.oh-my-zsh"
if [[ ! -d $ZSH ]]; then
    echo "~/.oh-my-zsh is not found. Cloning now."
    git clone https://github.com/ohmyzsh/ohmyzsh.git $ZSH
fi

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode disabled  # disable automatic updates

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

HIST_STAMPS="yyyy-mm-dd"

# Standard plugins can be found in $ZSH/plugins/
plugins=(git)

source $ZSH/oh-my-zsh.sh

#--------------------------------------------------
# Alias
#--------------------------------------------------
alias ipython='python3 -m IPython'
alias python='python3'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CFl '
#--------------------------------------------------

#--------------------------------------------------
# Lazy loading nvm, node and npm as it takes for ever on start.
#--------------------------------------------------
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

LAZY_LOAD_NVM=false
if ! $LAZY_LOAD_NVM; then
    load_nvm
else
    lazy_load_nvm_on_call() {
        local CMD=$1
        shift
        if [[ -z "$NVM_DIR" ]]; then
            load_nvm
        fi
    
        if [[ "$CMD" == "nvm" ]]; then
            eval "$CMD" "$@"
        else
            command "$CMD" "$@"
        fi
    }
    
    nvm() {
        lazy_load_nvm_on_call nvm "$@"
        unset -f nvm 
    }
    
    npm() {
        lazy_load_nvm_on_call npm "$@"
        unset -f npm
    }
    
    node() {
        lazy_load_nvm_on_call node "$@"
        unset -f node 
    }
fi
#--------------------------------------------------

#--------------------------------------------------
# PATHS
#--------------------------------------------------
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export EDITOR='nvim'
export SUDO_EDITOR="nvim"
export PATH="$HOME/.local/bin:$PATH"
#--------------------------------------------------

# past=$(date +%s%5N)
# From helpers.sh
if [[ -d "$HOME/software" ]]; then
    create_directory_and_add_to_path "$HOME/.local/nicholas/bin" 1
    sym_link_file_as_bin "$HOME/software/timer/timer.py" "$HOME/.local/nicholas/bin"
    
    VENVMAN_ROOT_DIR=$HOME/.venvman
    VENVMAN_ENVS_DIR=$HOME/.venvman/envs
    source_file "$HOME/.venvman/venvman/src/completion/completion.sh"
    venvman() {
        unset -f venvman
        source_file "$HOME/.venvman/venvman/src/main.sh"
        venvman $@
    }
fi
#--------------------------------------------------
# present=$(date +%s%5N)
# echo $(( present - past ))
