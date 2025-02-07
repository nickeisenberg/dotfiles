source $HOME/.bashrc
source $HOME/.credentials/password.sh
source $HOME/.credentials/keypairs/paths.sh

#--------------------------------------------------
# Settings
#--------------------------------------------------
xset r rate 250 30  # key press delay time 
#--------------------------------------------------

#--------------------------------------------------
# Alias
#--------------------------------------------------
alias ipython='python3 -m IPython'
alias python='python3'
#--------------------------------------------------

#--------------------------------------------------
# PATHS
#--------------------------------------------------
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

# nvm paths
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
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
