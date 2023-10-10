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
			tmux new-session -s $session -n editor -d  # Create a tmux pane named 'editor' and close it
			tmux split-window -t "$session:0.0" -h -p 40  # Split the pane into two horizontal panes
			tmux split-window -t "$session:0.1" -v -p 10  # Split the right pane verically
			if [ $_venv ]  # if a filename is entered on creation of tmux session, open the file with nvim
				then
					tmux send-keys -t "$session:0.1" "venv $_venv && python" C-m
					tmux send-keys -t "$session:0.0" "venv $_venv" C-m
				else
					tmux send-keys -t "$session:0.1" "python" C-m  # open python in the top right pane
			fi
			tmux select-pane -t "$session:0.0"  # return the focus to the main left pane
			# if [ $file_to_open ]  # if a filename is entered on creation of tmux session, open the file with nvim
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


# set the key light
function kli() {
	if [ $1 -lt 0 ] || [ $1 -gt 2 ] 
		then
			echo "Brightness must be 0, 1 or 2"
		else
			echo $1 | sudo tee /sys/class/leds/tpacpi::kbd_backlight/brightness
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


function venv() {
	source /home/nicholas/Software/venv/$1/bin/activate
}

function dm() {
	xrandr --output HDMI-1-0 --off
	xrandr --output HDMI-1-0 --auto
	xrandr --output HDMI-1-0 --noprimary --above eDP-1
}
