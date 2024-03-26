source ~/.bashrc
source ~/.hiddenvar

# nvm paths
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# sudo edit env variables
export SUDO_EDITOR="nvim"

# visidata path
export PATH=$PATH:~/.local/bin

for file in ~/dotfiles/scripts/*; do
    source $file
done
