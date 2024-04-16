source ~/.bashrc

# cuda toolkit paths
export PATH="$PATH:/usr/local/cuda-12.2/bin"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-12.2/lib64"
#--------------------------------------------------

export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

alias winh="cd /mnt/c/Users/EISENBNT"

for file in $HOME/dotfiles/scripts/*.sh; do
    source $file
done
