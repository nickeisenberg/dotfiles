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


function add_to_path() {
    if ! in_path $1; then
        if [[ $2  == 0 ]]; then
            PATH=$1:$PATH
        elif [[ $2 == 1 ]]; then
            PATH=$PATH:$1
        else
            echo "ERROR: second arg must be 0 or 1"
        fi
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
    elif [[ $# > 2 ]]; then
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


function create_directory_and_add_to_path() {
    if [[ ! -d $1 ]]; then
        mkdir -p $1
        if ! dir_exists $1; then
            echo "$1 was not successfully created"
            return 1
        fi
    fi

    if ! in_path $1; then
        add_directory_to_path $1 $2
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


function ensure_inputs() {
    local input_name
    local expected=()
    local inputed=()
    local current_option=""
    local i=1
    
    while (( i <= $# )); do
        case "${!i}" in
            --name)
                local current_option="name"
                ;;
            --expected)
                local current_option="expected"
                ;;
            --inputed)
                local current_option="inputed"
                ;;
            *)
                if [[ $current_option == "name" ]]; then
                    local input_name="${!i}"
                elif [[ $current_option == "expected" ]]; then
                    expected+=( "${!i}" )
                elif [[ $current_option == "inputed" ]]; then
                    inputed+=( "${!i}" )
                fi
                ;;
        esac
        ((i++))
    done

    if [[ -z $input_name || -z $inputed || -z $expected ]]; then
        echo "enter a --name --expected --inputed"
        return 1
    fi
    
    declare -A lookup
    for item in "${expected[@]}"; do
        lookup["$item"]=1
    done

    if [[ ${#inputed[@]} > 1 ]]; then
        echo "Option $input_name needs to be in ${expected[@]} but received ${inputed[@]}"
        return 1
    fi
    
    local input_found=true
    for item in "${inputed[@]}"; do
        if [[ -z "${lookup["$item"]}" ]]; then
            local input_found=false
            break
        fi
    done
    
    if [[ $input_found == true ]]; then
        echo $inputed
    else
        echo "Option $input_name needs to be in ${expected[@]} but received ${inputed[@]}"
        return 1
    fi
}
