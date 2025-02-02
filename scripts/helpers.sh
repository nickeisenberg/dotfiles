function dir_exists() {
    if [[ -d $1 ]]; then
        return 0
    else
        return 1
    fi
}


function sym_link_exists() {
    if [[ -L $1 ]]; then
        return 0
    else
        return 1
    fi 
}


function is_on_system() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}


function in_path() {
    if [[ ":$PATH:" == *":$1:"* ]]; then
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


function variable_is_set() {
    if [[ -n $1 ]]; then
        return 0
    else
        return 1
    fi
}


function add_directory_to_path() {
    if in_path $1; then
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

    if ! in_path $1; then
        echo "$1 has not been added to PATH"
        return 1
    else
        return 0
    fi
}


function setup_home_dotlocal_nicholas_bin() {
    local DIR="$HOME/.local/nicholas/bin"
    
    if [[ ! -d $DIR ]]; then
        mkdir -p $DIR

        if ! dir_exists $DIR; then
            echo "$DIR was not successfully created"
            return 1
        fi
    fi

    if ! in_path $DIR; then
        add_directory_to_path $DIR

        if ! in_path $DIR; then
            echo "$DIR was not successfully added to PATH"
            return 1
        else
            return 0
        fi
    fi
}


function sym_link_file_as_bin() {
    if [[ ! $# == 2 ]]; then
        echo "2 args must be given"
        return 1
    fi

    if [[ ! -f $1 ]]; then
        echo "$2 is not a directory"
    fi

    if [[ ! -d $2 ]]; then
        echo "$2 is not a directory"
    fi

    local BASENAME=$(basename $1)
    local FILENAME="${BASENAME%%.*}"
    chmod +x $1

    if ! sym_link_exists "$2/$FILENAME"; then
        ln -s $1 "$2/$FILENAME"

        if ! sym_link_exists "$2/$FILENAME"; then
            echo "sym link was not successfully created"
            return 1
        else
            return 0
        fi
    fi
}
