source ~/.bashrc

#--------------------------------------------------
# This occurred in the alacritty install
#--------------------------------------------------
. "$HOME/.cargo/env"
#--------------------------------------------------

xset r rate 250 30

# qtile script is here
export PATH="$PATH:/home/local/DEVNET/eisenbergn/.local/bin"

for file in $HOME/Dotfiles/scripts/*.sh; do
    source $file
done
