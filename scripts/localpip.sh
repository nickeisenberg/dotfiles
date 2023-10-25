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
        echo "-pl, --package-location         Display the directory location of the specified package."
        echo "-i, --install <repo_url>        Clone a repository directly into site-packages."
        echo "-un, --uninstall                Remove the specified package from site-packages."
        echo "-spl, --site-package-location   Display the site-packages directory location."
        echo "-h, --help                      Display this help and exit."
    }

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -p|--package)
                package_name="$2"
                package_dir="$site_packages_dir/$package_name"
                shift 2
                ;;
            -u|--update)
                if [[ -z "$package_name" ]]; then
                    echo "Please specify a package using -p or --package for this option."
                    return 1
                fi
                (cd "$package_dir" && git fetch --all && git reset --hard origin/master)
                shift
                ;;
            -gcc|--get-current-commit)
                if [[ -z "$package_name" ]]; then
                    echo "Please specify a package using -p or --package for this option."
                    return 1
                fi
                (cd "$package_dir" && git rev-parse HEAD)
                shift
                ;;
            -rt|--revert-to)
                if [[ -z "$package_name" ]]; then
                    echo "Please specify a package using -p or --package for this option."
                    return 1
                fi
                commit_hash="$2"
                (cd "$package_dir" && git reset --hard "$commit_hash")
                shift 2
                ;;
            -pl|--package-location)
                if [[ -z "$package_name" ]]; then
                    echo "Please specify a package using -p or --package for this option."
                    return 1
                fi
                echo "$package_dir"
                shift
                ;;
            -i|--install)
                repo_url="$2"
                (cd "$site_packages_dir" && git clone "$repo_url")
                shift 2
                ;;
            -un|--uninstall)
                if [[ -z "$package_name" ]]; then
                    echo "Please specify a package using -p or --package for this option."
                    return 1
                fi
                rm -rf "$package_dir"
                echo "Uninstalled $package_name from site-packages."
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

