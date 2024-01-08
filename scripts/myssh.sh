function myssh() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: myssh <option> [argument]"
        echo "Use 'myssh -h' or 'myssh --help' for a list of available options."
        return 1
    fi

    local port_forwarding=()
    local ip

    while [[ $# -gt 0 ]]; do
        case $1 in
            -jetex|--jetson-from-external)
                ip=$(jq -r '.external_home_ip' ~/.credentials/ipaddr.json)
                shift
                ;;
            -jetin|--jetson-from-internal)
                ip=$(jq -r '.eisenbnt_at_SDRD3' ~/.credentials/ipaddr.json)
                shift
                ;;
            -L)
                while [[ $# -gt 1 ]] && [[ $2 =~ ^[0-9]+$ ]]; do
                    port_forwarding+=("-L $2:localhost:$2")
                    shift
                done
                shift
                ;;
            -h|--help)
                echo "Usage: myssh <option> [argument]"
                echo "Options:"
                echo "-jetex|--jetson-from-external : SSH into the Jetson cube externally without port forwarding by default."
                echo "-jetin|--jetson-from-internal : SSH into the Jetson cube internally without port forwarding by default."
                echo "-L : Specify ports for local port forwarding. Can be used multiple times for multiple ports."
                return 0
                ;;
            *)
                echo "Invalid option. Use 'myssh -h' or 'myssh --help' for a list of available options."
                return 1
                ;;
        esac
    done

    ssh_command="ssh -p 2202"
    for pf in "${port_forwarding[@]}"; do
        ssh_command+=" $pf"
    done

    if [[ -n $ip ]]; then
        ssh_command+=" eisenbnt@$ip"
        eval $ssh_command
    else
        echo "No valid IP address found for connection."
        return 1
    fi
}
