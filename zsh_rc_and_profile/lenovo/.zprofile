#-------------------------------------------------- 
# Some helpers
#-------------------------------------------------- 
for file in $HOME/dotfiles/scripts/*; do
    source $file
done
#-------------------------------------------------- 

# Load NVM if it's not already loaded
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

lazy_load_nvm_on_call() {
    local CMD=$1
    shift
    if [[ -z "$NVM_DIR" ]]; then  # Check if NVM is not loaded
        load_nvm
    fi

    if [[ "$CMD" == "nvm" ]]; then
        eval "$CMD" "$@"  # Use eval for nvm since it's a function
    else
        command "$CMD" "$@"  # Use command for node/npm
    fi
}


# Override nvm, node, npm to use lazy loading
nvm() {
    lazy_load_nvm_on_call nvm "$@"
}

npm() {
    lazy_load_nvm_on_call npm "$@"
}

node() {
    lazy_load_nvm_on_call node "$@"
}
