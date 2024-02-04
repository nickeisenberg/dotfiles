function myssh() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: myssh <option> [argument]"
        echo "Use 'myssh -h' or 'myssh --help' for a list of available options."
        return 1
    fi

    local port_forwarding=()
    local ip
    local user
    local port
    local pem

    while [[ $# -gt 0 ]]; do
        case $1 in
            -jetex|--jetson-from-external)
                ip=$(jq -r '.external_home_ip' ~/.credentials/ipaddr.json)
                user=eisenbnt
                port=2202
                shift
                ;;
            -jetin|--jetson-from-internal)
                ip=$(jq -r '.eisenbnt_at_SDRD3' ~/.credentials/ipaddr.json)
                user=eisenbnt
                port=2202
                shift
                ;;
            -crsr|--crsr-aws)
                ip=$(jq -r '.crsr' ~/.credentials/ipaddr.json)
                user=eisenbnt
                port=22
                pem=$HOME/.credentials/keypairs/CRSR.pem
                shift
                ;;
            -crsradmin|--crsr-aws-ubuntu-profile)
                ip=$(jq -r '.crsr' ~/.credentials/ipaddr.json)
                user=ubuntu
                port=22
                pem=$HOME/.credentials/keypairs/CRSR.pem
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
                echo "-crsr|--crsr-aws : SSH into the crsr instnace without port forwarding by default."
                echo "-crsradmin|--crsr-aws-ubuntu-profile : SSH into the crsr ubuntu profile without port forwarding by default."
                echo "-L : Specify ports for local port forwarding. Can be used multiple times for multiple ports."
                return 0
                ;;
            *)
                echo "Invalid option. Use 'myssh -h' or 'myssh --help' for a list of available options."
                return 1
                ;;
        esac
    done

    ssh_command="ssh -p $port"

    if [[ -n $pem ]]; then
        ssh_command+=" -i $pem"
    fi

    for pf in "${port_forwarding[@]}"; do
        ssh_command+=" $pf"
    done

    if [[ -n $ip ]]; then
        ssh_command+=" $user@$ip"
        eval $ssh_command
    else
        echo "No valid IP address found for connection."
        return 1
    fi
}
