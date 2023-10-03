source ~/.bashrc

# key press delay time 
xset r rate 200 30

# cuda paths
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

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

function venv() {
	source /home/nicholas/Software/venv/$1/bin/activate
}













