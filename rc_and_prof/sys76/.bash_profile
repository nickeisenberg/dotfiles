source ~/.bashrc

#--------------------------------------------------
# This occurred in the alacritty install
#--------------------------------------------------
. "$HOME/.cargo/env"
#--------------------------------------------------

xset r rate 250 30

# qtile script is here
export PATH="$PATH:/home/local/DEVNET/eisenbergn/.local/bin"

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

for file in $HOME/dots_ubuntu/scripts/*.sh; do
    source $file
done
