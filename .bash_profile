source ~/.bashrc

# key press delay time 
xset r rate 250 30

# cuda paths
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

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

# some aliases
alias ipython='python3 -m IPython'
alias python='python3'


# display the gitbranch
parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
if [ "$color_prompt" = yes ]; then
 PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
 PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi

#--------------------------------------------------
# some functions
#--------------------------------------------------


for file in $HOME/Dotfiles/scripts/*; do
    source $file
done

# # quickly add commit and push to a branch
# function acp {
#     git add -A
#     git commit -m "$1"
#     git push -u origin $2
# }
# 
# # open neovim in config from any location. When cloing neovim
# # you will return to the same location
# function nvimc() (
#     cd -- ~/.config/nvim
#     nvim
# )
# 
# 
# # External screen brightness
# # The second arg is the monitor name. It can be left blank and defaults
# # to HDMI-1-0 which I believe will always be the monitor form the hdmi port
# function dmb(){
#     if [$2] 
#     	then
#     	    xrandr --output $2 --brightness $1
#     	else
#     	    xrandr --output HDMI-1-0 --brightness $1
#     fi
# }
# 
# 
# function dm() {
#     xrandr --output HDMI-1-0 --off
#     xrandr --output HDMI-1-0 --auto
#     xrandr --output HDMI-1-0 --noprimary --above eDP-1
# }
# 
# 
# function sshaws() {
#     ssh -i /home/nicholas/.credentials/keypairs/$1 $2
# }
# 
# 
# function venv() {
#     VENV_DIR="$HOME/Software/venv"
# 
#     # Check the number of arguments passed
#     if [[ $# -lt 1 ]]; then
#         echo "Usage: venv <-m/-a/-sp/-da/-ls/-h> [venv_name/package_name]"
#         return 1
#     fi
# 
#     # Check the first argument to determine the action
#     case $1 in
#         -m)
#             if [[ $# -ne 2 ]]; then
#                 echo "Usage: venv -m <venv_name>"
#                 return 1
#             fi
#             python3 -m venv "$VENV_DIR/$2"
# 	    echo "Virtual environment '$2' successfully created in $VENV_DIR/$2"
#             ;;
#         
#         -a)
#             if [[ $# -ne 2 ]]; then
#                 echo "Usage: venv -a <venv_name>"
#                 return 1
#             fi
#             if [[ -d "$VENV_DIR/$2" ]]; then
#                 source "$VENV_DIR/$2/bin/activate"
#             else
#                 echo "Error: Virtual environment '$2' does not exist in $VENV_DIR"
#             fi
#             ;;
#         
#         -sp)
#             SITE_PACKAGES_DIR=$(pip show pip | grep Location | awk '{print $2}')
# 
#             if [[ ! $SITE_PACKAGES_DIR ]]; then
#                 echo "Error: pip is not installed or the location cannot be determined"
#                 return 1
#             fi
# 
#             if [[ $# -eq 1 ]]; then
#                 cd "$SITE_PACKAGES_DIR"
#             elif [[ $# -eq 2 ]]; then
#                 if [[ -d "$SITE_PACKAGES_DIR/$2" ]]; then
#                     cd "$SITE_PACKAGES_DIR/$2"
#                 else
#                     echo "Error: Package '$2' does not exist in $SITE_PACKAGES_DIR"
#                     return 1
#                 fi
#             else
#                 echo "Usage: venv -sp [package_name]"
#                 return 1
#             fi
#             ;;
#         
#         -da)
#             if [[ -z "$VIRTUAL_ENV" ]]; then
#                 echo "No virtual environment is currently activated."
#                 return 1
#             fi
#             deactivate
#             ;;
#         
#         -ls)
#             echo "Available virtual environments:"
#             if [[ -d "$VENV_DIR" ]]; then
#                 ls "$VENV_DIR"
#             else
#                 echo "No virtual environments found in $VENV_DIR"
#             fi
#             ;;
# 
#         -del)
#             if [[ $# -ne 2 ]]; then
#                 echo "Usage: venv -del <venv_name>"
#                 return 1
#             fi
#             if [[ ! -d "$VENV_DIR/$2" ]]; then
#                 echo "Error: Virtual environment '$2' does not exist in $VENV_DIR"
#                 return 1
#             fi
#             read -p "Are you sure you want to delete virtual environment '$2'? [y/N]: " response
#             if [[ "$response" =~ ^[Yy]$ ]]; then
#                 rm -r "$VENV_DIR/$2"
#                 echo "Virtual environment '$2' has been deleted."
#             else
#                 echo "Deletion cancelled."
#             fi
#             ;;
# 
#         
#         -h)
#             echo "Usage: venv <option> [argument]"
#             echo "Options:"
#             echo "  -m <venv_name>      : Create a new virtual environment."
#             echo "  -a <venv_name>      : Activate the specified virtual environment."
#             echo "  -sp [package_name]  : Navigate to the site-packages directory or specified package directory."
#             echo "  -da                 : Deactivate the currently active virtual environment."
#             echo "  -ls                 : List all available virtual environments in $VENV_DIR."
#             echo "  -h                  : Display this help message."
#             ;;
#         
#         *)
#             echo "Invalid option. Use 'venv -h' for a list of available options."
#             return 1
#             ;;
#     esac
# }
# 
# 
# function ide() {
#     local NAME="default_session"
#     local VENV=""
#     local OPEN_WITH=""
#     local PYTHON=false
# 
#     if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
#         echo "Usage: ide [OPTIONS]"
#         echo ""
#         echo "Options:"
#         echo "  -n, --name        Name of the tmux session (default: default_session)"
#         echo "  -v, --venv        Virtual environment to activate in tmux panes"
#         echo "  -ow, --open-with  File to open in neovim on the left pane"
#         echo "  -p, --python      Open python interpreter in the top right pane"
#         echo "  -h, --help        Display this help message and exit"
#         return 0
#     fi
# 
#     while [[ "$#" -gt 0 ]]; do
#         case $1 in
#             -n|--name) NAME="$2"; shift ;;
#             -v|--venv) VENV="$2"; shift ;;
#             -ow|--open-with) OPEN_WITH="$2"; shift ;;
#             -p|--python) PYTHON=true ;;
#             *) echo "Unknown parameter passed: $1. Use -h or --help for usage information."; return 1 ;;
#         esac
#         shift
#     done
# 
#     # Check if session with given name already exists
#     tmux has-session -t "$NAME"
#     if [ $? == 0 ]; then
#         # The session exists, so attach to it and exit
#         tmux attach-session -t "$NAME"
#         return 0
#     fi
# 
#     # If we reached here, the session does not exist, so create and configure it
#         
#     # Start tmux session
#     tmux new-session -s "$NAME" -n editor -d
# 
#     # Split the window into left and right panes
#     tmux split-window -t "$NAME:0.0" -h -p 40 
#     # Split the right pane verically
#     tmux split-window -t "$NAME:0.1" -v -p 10  
# 
# 
#     # Apply --venv to all panes if set
#     if [ ! -z "$VENV" ]; then
#         for pane in $(tmux list-panes -F '#{pane_id}'); do
#             tmux send-keys -t "$pane" "venv -a $VENV" C-m
#         done
#     fi
# 
#     # Open file in neovim in left pane if --open-with is set
#     if [ ! -z "$OPEN_WITH" ]; then
#         # tmux send-keys -t 0 "nvim $OPEN_WITH" C-m
#         tmux send-keys -t "$NAME:0.0" "sleep .2 && clear && nvim $OPEN_WITH" C-m
#     fi
# 
#     # Run python in the top right pane if --python is set
#     if $PYTHON; then
#         # tmux send-keys -t  "python" C-m
#         tmux send-keys -t "$NAME:0.1" "python" C-m  
#     fi
# 
#     # Attach to the newly created tmux session
#     tmux attach-session -t "$NAME"
# }
