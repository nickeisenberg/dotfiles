# A simple venv maneger. There is one bit of user configuration which is setting
# the VENV_DIR variable in the first line of the function
# This tool will ...
# 1) make venv's with -m and store then in the VENV_DIR location.
# 2) activate venvs with -a
# 3) deactivate with -da 
# 4) go to the site packages within the venv with -sp
# 5) go to a specific foler in the site packages with -sp <packagename>
# 6) list all available venv's with ls 

function venv() {
    VENV_DIR="$HOME/Software/venv"

    # Check the number of arguments passed
    if [[ $# -lt 1 ]]; then
        echo "Usage: venv <-m/-a/-sp/-da/-ls/-del/-h> [venv_name/package_name]"
        return 1
    fi

    # Check the first argument to determine the action
    case $1 in
        -m)
            if [[ $# -ne 2 ]]; then
                echo "Usage: venv -m <venv_name>"
                return 1
            fi
            python3 -m venv "$VENV_DIR/$2"
	    echo "Virtual environment '$2' successfully created in $VENV_DIR/$2"
            ;;
        
        -a)
            if [[ $# -ne 2 ]]; then
                echo "Usage: venv -a <venv_name>"
                return 1
            fi
            if [[ -d "$VENV_DIR/$2" ]]; then
                source "$VENV_DIR/$2/bin/activate"
            else
                echo "Error: Virtual environment '$2' does not exist in $VENV_DIR"
            fi
            ;;
        
        -sp)
            SITE_PACKAGES_DIR=$(pip show pip | grep Location | awk '{print $2}')

            if [[ ! $SITE_PACKAGES_DIR ]]; then
                echo "Error: pip is not installed or the location cannot be determined"
                return 1
            fi

            if [[ $# -eq 1 ]]; then
                cd "$SITE_PACKAGES_DIR"
            elif [[ $# -eq 2 ]]; then
                if [[ -d "$SITE_PACKAGES_DIR/$2" ]]; then
                    cd "$SITE_PACKAGES_DIR/$2"
                else
                    echo "Error: Package '$2' does not exist in $SITE_PACKAGES_DIR"
                    return 1
                fi
            else
                echo "Usage: venv -sp [package_name]"
                return 1
            fi
            ;;
        
        -da)
            if [[ -z "$VIRTUAL_ENV" ]]; then
                echo "No virtual environment is currently activated."
                return 1
            fi
            deactivate
            ;;
        
        -ls)
            echo "Available virtual environments:"
            if [[ -d "$VENV_DIR" ]]; then
                ls "$VENV_DIR"
            else
                echo "No virtual environments found in $VENV_DIR"
            fi
            ;;

        -del)
            if [[ $# -ne 2 ]]; then
                echo "Usage: venv -del <venv_name>"
                return 1
            fi
            if [[ ! -d "$VENV_DIR/$2" ]]; then
                echo "Error: Virtual environment '$2' does not exist in $VENV_DIR"
                return 1
            fi
            read -p "Are you sure you want to delete virtual environment '$2'? [y/N]: " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -rf "$VENV_DIR/$2"
                echo "Virtual environment '$2' has been deleted."
            else
                echo "Deletion cancelled."
            fi
            ;;

        
        -h)
            echo "Usage: venv <option> [argument]"
            echo "Options:"
            echo "  -m <venv_name>      : Create a new virtual environment."
            echo "  -a <venv_name>      : Activate the specified virtual environment."
            echo "  -sp [package_name]  : Navigate to the site-packages directory or specified package directory."
            echo "  -da                 : Deactivate the currently active virtual environment."
            echo "  -ls                 : List all available virtual environments in $VENV_DIR."
            echo "  -del                : Delete the specified venv."
            echo "  -h                  : Display this help message."
            ;;
        
        *)
            echo "Invalid option. Use 'venv -h' for a list of available options."
            return 1
            ;;
    esac
}
