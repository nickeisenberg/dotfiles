#! /bin/bash

# This is a localpip python package maneger. If you add gitrepos to your site
# then localpip gives a way to update the repo quickly without needed to go to
# the site-package directory itself.
#
localpip() {
    # Get the site-packages directory
    site_packages_dir=$(pip show pip | grep Location | cut -d' ' -f2)

    # Helper function to display usage
    display_help() {
        echo "Usage: localpip [OPTIONS]"
        echo "-pn, --package-name <name>      Specify the package folder inside site-packages."
        echo "-u, --update                    Update the specified package."
        echo "-gcc, --get-current-commit      Get the current commit of the specified package."
        echo "-rt, --revert-to <commit>       Revert the specified package to a given commit."
        echo "-pl, --package-location         Display the directory location of the specified package."
        echo "-i, --install <repo_url>        Clone a repository directly into site-packages with an optional specified name."
        echo "-un, --uninstall                Remove the specified package from site-packages."
        echo "-ls, --list                      List all packages potentially installed with localpip."
        echo "-spl, --site-package-location   Display the site-packages directory location."
        echo "-h, --help                      Display this help and exit."
    }

    list_localpip_packages() {
        echo "Packages potentially installed with localpip:"
        for dir in "$site_packages_dir"/*; do
            if [[ -d "$dir/.git" ]]; then
                basename "$dir"
            fi
        done
    }

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -pn|--package-name)
                package_name="$2"
                package_dir="$site_packages_dir/$package_name"
                shift 2
                ;;
            -u|--update)
                (cd "$package_dir" && git fetch --all && git reset --hard origin/master)
                shift
                ;;
            -gcc|--get-current-commit)
                (cd "$package_dir" && git rev-parse HEAD)
                shift
                ;;
            -rt|--revert-to)
                commit_hash="$2"
                (cd "$package_dir" && git reset --hard "$commit_hash")
                shift 2
                ;;
            -pl|--package-location)
                echo "$package_dir"
                shift
                ;;
            -i|--install)
                repo_url="$2"
                temp_dir=$(mktemp -d)
                (cd "$temp_dir" && git clone "$repo_url")
                
                # If package_name is set, rename the cloned directory. Else use repo's name.
                repo_name=$(basename "$temp_dir"/* .git)
                mv "$temp_dir/$repo_name" "$site_packages_dir/${package_name:-$repo_name}"
                
                rm -rf "$temp_dir"
                shift 2
                ;;
            -un|--uninstall)
                rm -rf "$package_dir"
                echo "Uninstalled $package_name from site-packages."
                shift
                ;;
            -ls|--list)
                list_localpip_packages
                shift
                ;;
            -spl|--site-package-location)
                echo "$site_packages_dir"
                shift
                ;;
            -h|--help)
                display_help
                return 0
                ;;
            *)
                echo "Unknown argument: $1"
                display_help
                return 1
                ;;
        esac
    done
}

