# quickly add commit and push all to a git repo's branch

function acp {
    local message=""
    local remote=""
    local branch_name=""

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --message|-m) 
                message="$2"
                shift
                ;;
            --remote|-r)
                remote="$2"
                shift
                ;;
            --branch-name|-b)
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

    if [[ -z "$message" ]] || [[ -z "$branch_name" ]] || [[ -z "$remote" ]]; then
        echo "Please provide both --message | -m, --remote | -r and --branch-name | -b"
        return 1
    fi

    git add -A
    git commit -m "$message"
    git push -u $remote "$branch_name"
}
