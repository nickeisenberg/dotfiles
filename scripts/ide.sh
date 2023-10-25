# A function that opens up a tmux pane in an IDE like enviornment.
#  __________________________
# |            |            |
# |            |            |
# |  Pane 0    |  Pane 1    |
# |            |            |
# |            |____________|
# |            |  Pane 2    |
# |____________|____________|
#

function ide() {
    local NAME="default_session"
    local VENV=""
    local OPEN_WITH=""
    local PYTHON=false

    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        echo "Usage: ide [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -n, --name        Name of the tmux session (default: default_session)"
        echo "  -v, --venv        Virtual environment to activate in tmux panes"
        echo "  -ow, --open-with  File to open in neovim on the left pane"
        echo "  -p, --python      Open python interpreter in the top right pane"
        echo "  -h, --help        Display this help message and exit"
        return 0
    fi

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -n|--name) NAME="$2"; shift ;;
            -v|--venv) VENV="$2"; shift ;;
            -ow|--open-with) OPEN_WITH="$2"; shift ;;
            -p|--python) PYTHON=true ;;
            *) echo "Unknown parameter passed: $1. Use -h or --help for usage information."; return 1 ;;
        esac
        shift
    done

    # Check if session with given name already exists
    tmux has-session -t "$NAME"
    if [ $? == 0 ]; then
        # The session exists, so attach to it and exit
        tmux attach-session -t "$NAME"
        return 0
    fi

    # If we reached here, the session does not exist, so create and configure it
        
    # Start tmux session
    tmux new-session -s "$NAME" -n editor -d

    # Split the window into left and right panes
    tmux split-window -t "$NAME:0.0" -h -p 40 
    # Split the right pane verically
    tmux split-window -t "$NAME:0.1" -v -p 10  


    # Apply --venv to all panes if set
    if [ ! -z "$VENV" ]; then
        for pane in $(tmux list-panes -F '#{pane_id}'); do
            tmux send-keys -t "$pane" "venv -a $VENV" C-m
        done
    fi

    # Open file in neovim in left pane if --open-with is set
    if [ ! -z "$OPEN_WITH" ]; then
        # tmux send-keys -t 0 "nvim $OPEN_WITH" C-m
        tmux send-keys -t "$NAME:0.0" "sleep .2 && clear && nvim $OPEN_WITH" C-m
    fi

    # Run python in the top right pane if --python is set
    if $PYTHON; then
        # tmux send-keys -t  "python" C-m
        tmux send-keys -t "$NAME:0.1" "python" C-m  
    fi

    # Attach to the newly created tmux session
    tmux attach-session -t "$NAME"
}
