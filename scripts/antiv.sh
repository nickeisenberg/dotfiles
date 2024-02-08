antiv() {
  if [ $# -ne 1 ]; then
    echo "Error: You must provide exactly one argument."
    return 1
  fi

  case $1 in
    on)
      echo "Turning on antivirus"
      sudo /opt/McAfee/ens/tp/init/mfetpd-control.sh start
      ;;
    off)
      echo "Turning off antivirus"
      sudo /opt/McAfee/ens/tp/init/mfetpd-control.sh stop
      ;;
    status)
      echo "Checking status antivirus"
      sudo /opt/McAfee/ens/tp/init/mfetpd-control.sh status
      # Place your command for "on" here
      ;;
    *)
      echo "Error: You must enter 'on', 'off' or 'status'."
      return 2
      ;;
  esac
}
