#-------------------------------------------------- 
# Some helpers
#-------------------------------------------------- 
source $HOME/dotfiles/scripts/helpers.sh
source $HOME/dotfiles/scripts/dm.sh
#-------------------------------------------------- 

autoload -Uz compinit
compinit

autoload -Uz colors && colors

parse_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -n $branch ]] && echo " ($branch)"
}

set_prompt() {
	FANCY=false

	PROMPT_NO_STATUS="%{$fg_bold[green]%}%n@%m%{$reset_color%}:%{$fg_bold[blue]%}%1~%{$fg_bold[red]%}$(parse_git_branch)%{$reset_color%} \$ "
	PROMPT_STATUS="%{$fg_bold[green]%}%n@%m%{$reset_color%}:%{$fg_bold[blue]%}%1~%{$fg_bold[red]%}$(parse_git_branch)%{$reset_color%} (x) \$ "

	if $FANCY; then
		STATUS=$(git status --short 2> /dev/null)
	fi

	if [ -n "$STATUS" ]; then
	  PROMPT=$PROMPT_STATUS
	else
	  PROMPT=$PROMPT_NO_STATUS
	fi

    if [ -n "$VIRTUAL_ENV_PROMPT" ]; then
        PROMPT="${VIRTUAL_ENV_PROMPT} ${PROMPT}"
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt

#--------------------------------------------------
# Alias
#--------------------------------------------------
alias ls='ls -G'
alias ll='ls -alFG'
alias la='ls -AG'
alias l='ls -CFlG'
#--------------------------------------------------

VENVMAN_ROOT_DIR=$HOME/.venvman
source "$HOME/.venvman/venvman/src/main.sh"

#--------------------------------------------------

PATH="${HOME}/.local/src/miniconda3/bin:${PATH}"
PATH="${HOME}/.local/src/nvm/versions/node/v22.14.0/bin:${PATH}"
PATH="${HOME}/.local/src/brew/bin:${PATH}"
PATH="/Library/Frameworks/Python.framework/Versions/3.11/bin:${PATH}"
PATH="${HOME}/.local/bin:${PATH}"

nvm() {
    unset -f nvm
    export NVM_DIR="$HOME/.local/src/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    nvm $@
}
