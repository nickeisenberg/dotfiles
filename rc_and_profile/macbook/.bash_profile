source ~/.bashrc

# python path
# PATH="/Library/Frameworks/Python.framework/Versions/3.10/bin:${PATH}"
# export PATH

# add mysql to path
export PATH=${PATH}:/usr/local/mysql/bin/

alias mysqlstart='sudo /usr/local/mysql/support-files/mysql.server start'
alias mysqlstop='sudo /usr/local/mysql/support-files/mysql.server stop' 

# add texlive to path for vscode
export PATH=${PATH}:/usr/local/texlive/2022/bin/universal-darwin/

for file in $HOME/Software/venv_manager/venv/*.sh ; do
    source $file
done
