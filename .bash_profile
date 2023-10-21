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

# some functions

# quickly add commit and push to a branch
function acp {
	git add -A
	git commit -m "$1"
	git push -u origin $2
}

# open neovim in config from any location. When cloing neovim
# you will return to the same location
function nvimc() (
	cd -- ~/.config/nvim
	nvim
)

# Create a tmux ide
# Useful tmux links
#	https://tmuxcheatsheet.com
#	https://stackoverflow.com/questions/38325737/tmux-split-window-and-activate-a-python-virtualenv
function ide() {
	session=$1
	# file_to_open=$2
	_venv=$2
	tmux has-session -t $session
	if [ $? != 0 ]
		then

			# Create a tmux pane named 'editor' and close it
			tmux new-session -s $session -n editor -d  
			# Split the pane into two horizontal panes
			tmux split-window -t "$session:0.0" -h -p 40 
			# Split the right pane verically
			tmux split-window -t "$session:0.1" -v -p 10  

			# if a filename is entered on creation of tmux session, open the file with nvim
			if [ $_venv ]  
				then
					tmux send-keys -t "$session:0.1" "avenv $_venv && python" C-m
					tmux send-keys -t "$session:0.0" "avenv $_venv" C-m
				else
					# open python in the top right pane
					tmux send-keys -t "$session:0.1" "python" C-m  
			fi

			# return the focus to the main left pane
			tmux select-pane -t "$session:0.0"  
			# if a filename is entered on creation of tmux session, open the file with nvim
			# if [ $file_to_open ]  
			# 	then
			# 		tmux send-keys -t "$session:0.0" "sleep .2 && clear && nvim $file_to_open" C-m
			# fi
			tmux attach -t $session  # open the tmux session

		else
			tmux attach -t $session
			# tmux kill-session
			# tmux new-session -s $session -n editor -d 
			# tmux split-window -t "$session:0.0" -h
			# tmux split-window -t "$session:0.1" -v -p 5
			# tmux attach -t $session
			# echo 'SESSION ALREADY EXISTS'
		fi
}


# External screen brightness
# The second arg is the monitor name. It can be left blank and defaults
# to HDMI-1-0 which I believe will always be the monitor form the hdmi port
function dmb(){
	if [$2] 
		then
			xrandr --output $2 --brightness $1
		else
			xrandr --output HDMI-1-0 --brightness $1
	fi
}

# function venv() (
# 	cd ~/Software/venv 
# 	python -m venv $1
# 	dir=$(pwd)
# 	echo "venv has been created to $dir/$1"
# )
# 
# function avenv() {
# 	source /home/nicholas/Software/venv/$1/bin/activate
# }
# 
# function lsvenv() {
# 	ls /home/nicholas/Software/venv/
# }
# 
# function sp() {
# 	dir=$(pip show pip | awk '/Location/ {print $2}')
# 	cd $dir
# }

function dm() {
	xrandr --output HDMI-1-0 --off
	xrandr --output HDMI-1-0 --auto
	xrandr --output HDMI-1-0 --noprimary --above eDP-1
}

function sshaws() {
	ssh -i /home/nicholas/.credentials/keypairs/$1 $2
}

function venv() {
    VENV_DIR="$HOME/Software/venv"

    # Check the number of arguments passed
    if [[ $# -lt 1 ]]; then
        echo "Usage: venv <-m/-a/-sp/-da/-ls/-h> [venv_name/package_name]"
        return 1
    fi

    # Check the first argument to determine the action
    case $1 in
        -m)
            if [[ $# -ne 2 ]]; then
                echo "Usage: venv -m <venv_name>"
                return 1
            fi
            python3 -m venv "$VENV_DIR/$2"
	    echo "Virtual environment '$2' successfully created in $VENV_DIR/$2"
            ;;
        
        -a)
            if [[ $# -ne 2 ]]; then
                echo "Usage: venv -a <venv_name>"
                return 1
            fi
            if [[ -d "$VENV_DIR/$2" ]]; then
                source "$VENV_DIR/$2/bin/activate"
            else
                echo "Error: Virtual environment '$2' does not exist in $VENV_DIR"
            fi
            ;;
        
        -sp)
            SITE_PACKAGES_DIR=$(pip show pip | grep Location | awk '{print $2}')

            if [[ ! $SITE_PACKAGES_DIR ]]; then
                echo "Error: pip is not installed or the location cannot be determined"
                return 1
            fi

            if [[ $# -eq 1 ]]; then
                cd "$SITE_PACKAGES_DIR"
            elif [[ $# -eq 2 ]]; then
                if [[ -d "$SITE_PACKAGES_DIR/$2" ]]; then
                    cd "$SITE_PACKAGES_DIR/$2"
                else
                    echo "Error: Package '$2' does not exist in $SITE_PACKAGES_DIR"
                    return 1
                fi
            else
                echo "Usage: venv -sp [package_name]"
                return 1
            fi
            ;;
        
        -da)
            if [[ -z "$VIRTUAL_ENV" ]]; then
                echo "No virtual environment is currently activated."
                return 1
            fi
            deactivate
            ;;
        
        -ls)
            echo "Available virtual environments:"
            if [[ -d "$VENV_DIR" ]]; then
                ls "$VENV_DIR"
            else
                echo "No virtual environments found in $VENV_DIR"
            fi
            ;;

        -del)
            if [[ $# -ne 2 ]]; then
                echo "Usage: venv -del <venv_name>"
                return 1
            fi
            if [[ ! -d "$VENV_DIR/$2" ]]; then
                echo "Error: Virtual environment '$2' does not exist in $VENV_DIR"
                return 1
            fi
            read -p "Are you sure you want to delete virtual environment '$2'? [y/N]: " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -r "$VENV_DIR/$2"
                echo "Virtual environment '$2' has been deleted."
            else
                echo "Deletion cancelled."
            fi
            ;;

        
        -h)
            echo "Usage: venv <option> [argument]"
            echo "Options:"
            echo "  -m <venv_name>      : Create a new virtual environment."
            echo "  -a <venv_name>      : Activate the specified virtual environment."
            echo "  -sp [package_name]  : Navigate to the site-packages directory or specified package directory."
            echo "  -da                 : Deactivate the currently active virtual environment."
            echo "  -ls                 : List all available virtual environments in $VENV_DIR."
            echo "  -h                  : Display this help message."
            ;;
        
        *)
            echo "Invalid option. Use 'venv -h' for a list of available options."
            return 1
            ;;
    esac
}
