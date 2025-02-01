function is_on_system() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}


function get_git_branch() {
    if is_on_system git; then
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
    else
        echo
    fi
}


function source_file() {
    if [[ -f $1 ]]; then
        source $1
    else
        echo "$1 is not a file" 
    fi
}


function in_path() {
    if [[ ":$PATH:" == *":$1:"* ]]; then
        return 0
    else
        return 1
    fi
}


function variable_is_set() {
    if [[ -n $1 ]]; then
        return 0
    else
        return 1
    fi
}


function add_directory_to_path() {
    if in_path $1; then
        echo "$1 is already in PATH"
        return 0
    fi

    if [[ $# -eq 2 && $2 -ne 0 && $2 -ne 1 ]]; then
        echo "second arg should be 0 or 1"
        echo return 1
    elif [[ $# -ge 2 ]]; then
        echo "len of args needs to be 1 or 2. $# args inputed"
        echo return 1
    fi

    if [[ ! -d "$1" ]]; then
        echo $1 does not exist
        return 1
    else
        if [[ $# == 2 && $2 == "0" ]]; then
            export PATH=$1:$PATH
        else
            export PATH=$PATH:$1
        fi
    fi

    if in_path $1; then
        echo "$1 has been added to PATH"
        return 0
    else
        echo "$1 has not been added to PATH"
        return 1
    fi
}


function setup_my_bin() {
    local MY_BIN_DIR="$HOME/.local/nicholas/bin"
    local SUCCESS

    if [[ ! -d "$MY_BIN_DIR" ]]; then
        echo "$MY_BIN_DIR does not exit."
        read -p "Should I create it and add it to PATH? [y/N]" response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            mkdir -p $MY_BIN_DIR
            if [[ -d $MY_BIN_DIR ]]; then
                echo "$MY_BIN_DIR has been created"
                SUCCESS="true"
            else
                echo "FAIL: $MY_BIN_DIR has not been created"
                SUCCESS="false"
            fi

            export PATH=$PATH:$MY_BIN_DIR
            if [[ $(in_path MY_BIN_DIR)=="true" ]]; then
                echo "$MY_BIN_DIR has been added to path"
                SUCCESS="true"
            else
                echo "FAIL: $MY_BIN_DIR has not been added to path"
                SUCCESS="false"
            fi
        fi
    else
        if [[ $(in_path "$MY_BIN_DIR") == "false" ]]; then
            echo "$MY_BIN_DIR is not in PATH."
            read -p "Should I add it to PATH? [y/N]" response

            if [[ "$response" =~ ^[Yy]$ ]]; then
                export PATH=$PATH:$MY_BIN_DIR
            fi

            if [[ $(in_path MY_BIN_DIR) == "true" ]]; then
                echo "$MY_BIN_DIR has been added to path"
                SUCCESS="true"
            else
                echo "FAIL: $MY_BIN_DIR has not been added to path"
                SUCCESS="false"
            fi
        else
            SUCCESS="true"
        fi
    fi
    echo $SUCCESS
}
