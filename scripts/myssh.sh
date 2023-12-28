function myssh() {
    
    if [[ $# -lt 1 ]]; then
        echo "Usage: myssh <option> [argument]"
        echo "Use 'myssh -h' or 'myssh --help' for a list of available options."
        return 1
    fi


    case $1 in

        -jetex|--jetson-from-external)
            ip=$(jq -r '.external_home_ip' ~/.credentials/ipaddr.json)
            ssh -p 2202 -L 7474:localhost:7474 -L 7687:localhost:7687 "eisenbnt@$ip"
            ;;

        -jetin|--jetson-from-external)
            ip=$(jq -r '.eisenbnt_at_SDRD3' ~/.credentials/ipaddr.json)
            ssh -p 2202 -L 7474:localhost:7474 -L 7687:localhost:7687 "eisenbnt@$ip"
            ;;

        -h|--help)
            echo "Usage: venv <option> [argument]"
            echo "Options:"

            echo "-jetex|--jetson-from-external :"
            echo -e "\t SSH into the Jetson cube externally. A tunnel is created for"
            echo -e "\t 7474:localhost:7474 and 7687:localhost:7687 to account for neo4j"

            echo "-jetin|--jetson-from-internal :"
            echo -e "\t SSH into the Jetson cube internally. A tunnel is created for"
            echo -e "\t 7474:localhost:7474 and 7687:localhost:7687 to account for neo4j"
            ;;

        *)
            echo "Invalid option. Use 'myssh -h' or 'myssh --help' for a list of available options."
            return 1
            ;;
    esac
}
