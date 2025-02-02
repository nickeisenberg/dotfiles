source $HOME/.bashrc
source $HOME/.credentials/password.sh
source $HOME/.credentials/keypairs/paths.sh

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
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
#--------------------------------------------------

#--------------------------------------------------
# Settings
#--------------------------------------------------
xset r rate 250 30  # key press delay time 
#--------------------------------------------------

#--------------------------------------------------
# My utilities
#--------------------------------------------------

# From helpers.sh
if [[ -d "$HOME/software" ]]; then
    source_file "$HOME/software/venv_manager/src/venv.sh"
    source_file "$HOME/software/tmux_ide/ide.sh"

    create_directory_and_add_to_path "$HOME/.local/nicholas/bin" 1
    sym_link_file_as_bin "$HOME/software/timer/timer.py" "$HOME/.local/nicholas/bin"
fi
#--------------------------------------------------
