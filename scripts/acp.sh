# quickly add commit and push all to a git repo's branch

function acp {
    local message=""
    local branch_name=""

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --message|-m) 
                message="$2"
                shift
                ;;
            --branch-name|-bn)
                branch_name="$2"
                shift
                ;;
            *)
                echo "Unknown parameter: $1"
                return 1
                ;;
        esac
        shift
    done

    if [[ -z "$message" ]] || [[ -z "$branch_name" ]]; then
        echo "Please provide both --message and --branch-name"
        return 1
    fi

    git add -A
    git commit -m "$message"
    git push -u origin "$branch_name"
}
