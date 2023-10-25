#! /bin/bash

# This is a localpip python package maneger. If you add gitrepos to your site
# then localpip gives a way to update the repo quickly without needed to go to
# the site-package directory itself.

localpip() {
    # Get the site-packages directory
    site_packages_dir=$(pip show pip | grep Location | cut -d' ' -f2)

    # Helper function to display usage
    display_help() {
        echo "Usage: localpip [OPTIONS]"
        echo "-p, --package <foldername>      Specify the package folder inside site-packages."
        echo "-u, --update                    Update the specified package."
        echo "-gcc, --get-current-commit      Get the current commit of the specified package."
        echo "-rt, --revert-to <commit>       Revert the specified package to a given commit."
        echo "-pdl, --package-dir-location    Display the directory location of the specified package."
        echo "-h, --help                      Display this help and exit."
    }

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -p|--package)
                package_name="$2"
                package_dir="$site_packages_dir/$package_name"
                
                # Check if the package directory exists
                if [[ ! -d "$package_dir" ]]; then
                    echo "Package directory $package_dir does not exist."
                    return 1
                fi
                
                # Check if there's a .git directory inside
                if [[ ! -d "$package_dir/.git" ]]; then
                    echo "Directory $package_dir is not a git repository."
                    return 1
                fi
                
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
            -pdl|--package-dir-location)
                echo "$package_dir"
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

    # Check if any action was specified without a package
    if [[ -z "$package_name" && $1 != "-h" && $1 != "--help" ]]; then
        echo "Please specify a package using -p or --package."
        return 1
    fi
}
