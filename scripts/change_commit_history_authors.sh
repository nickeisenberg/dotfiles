change_commit_history_authors() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --where)
                while [ "$1" != "--to" ]; do
                    case "$2" in
                        --email)
                            where_email="$3"
                            shift 2
                            ;;
                        --name)
                            where_name="$3"
                            shift 2
                            ;;
                        *)
                            shift 1
                            ;;
                    esac
                done
                ;;

            --to)
                while [ "$#" -gt 0 ]; do
                    case "$2" in
                        --email)
                            to_email="$3"
                            shift 2
                            ;;
                        --name)
                            to_name="$3"
                            shift 2
                            ;;
                        *)
                            shift 1
                            ;;
                    esac
                done
                ;;
            *)
                return 1
                ;;
        esac 
    done

    CMD="git-filter-repo --commit-callback '"

    where=""
    if [ -n "$where_name" ]; then
        where="if commit.commiter_name == b\"${where_name}\""
    fi

    if [ -n "$where_email" ] && [ -n "$where" ]; then
        where="${where} and commit.author_email == b\"${where_email}\""
	elif [ -n "$where_email" ]; then
        where="commit.author_email == \"${where_email}\""
    fi

    CMD="${CMD}\n${where}:"
    
    to=""
    if [ -n "$to_name" ]; then
        to="${to}\n\tcommit.author_name = b\"${to_name}\""
        to="${to}\n\tcommit.committer_name = b\"${to_name}\""
    fi

    if [ -n "$to_email" ]; then
        to="${to}\n\tcommit.author_email = b\"${to_email}\""
        to="${to}\n\tcommit.committer_email = b\"${to_email}\""
    fi

    CMD="${CMD}${to}\n'"
    echo $CMD
}

change_commit_history_authors --where --name Nick --to --name nick
