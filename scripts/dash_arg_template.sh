function dash_arg_template() {
    while [ $# -gt 0 ]; do
        case $1 in
            -a )
                echo "a is $2"
                shift 2
                ;;
            -b )
                echo "b is $2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
}
