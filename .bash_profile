source ~/.bashrc

# for file in ~/.config/helper_funcs/*.sh; do
#     source "$file"
# done

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
alias kts='tmux kill-session'

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
# after each tmux line you can specify the editor you want opened
# eg: python, nvim, vim, bash, etc
# Leaving it black will default to the standard shell
function ide() {
	session=$1
	tmux has-session -t $session
	if [ $? != 0 ]
		then
			tmux new-session -s $session -n editor -d  # <dif_editor_name>
			tmux split-window -t "$session:0.0" -h -p 40
			tmux split-window -t "$session:0.1" -v -p 5
			tmux attach -t $session
		else
			tmux attach -t $session
			tmux kill-session
			tmux new-session -s $session -n editor -d 
			tmux split-window -t "$session:0.0" -h
			tmux split-window -t "$session:0.1" -v -p 5
			tmux attach -t $session
			echo 'SESSION ALREADY EXISTS'
		fi
}
