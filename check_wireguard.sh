#!/usr/bin/env bash

# Source: https://github.com/inuits/monitoring-plugins/blob/master/check_wireguard

# Checks if the wireguard interface is present
# Script is roughly based on Dave Simons' check_ipsec script.

#helper functions
die () {
  RETVAL=$1
  shift
  echo $@
  exit $RETVAL
}

help () {
cat <<EOF
Usage: $0 -t <TUNNEL_NAME>

Options:
 -h   display this help and exit
 -c   set the wireguard config dir. Default: /etc/wireguard
 -t   set tunnel name

 Exit status:
  0    if tunnel is present
  2    if the tunnel or its config file is absent
  3    if the check returns an exit code that is neither 0 or 1
EOF

exit 0
}

# Default value
CONFIG_DIR='/etc/wireguard/'

# Parse command line switches
while getopts "hc:t:" OPTS; do
        case "$OPTS" in
                h) help ;;
                c) CONFIG_DIR="$OPTARG" ;;
                t) TUNN_NAME="$OPTARG" ;;
        esac
done

# Validate input
[[ -z "$TUNN_NAME" ]] && die 2 "[ERROR] No tunnel name specified"

# Check if config file is present
TUNN_CFG=$(find $CONFIG_DIR -name $TUNN_NAME* | grep .)
[ -z "$TUNN_CFG" ] && die 2 "[CRITICAL] No config file for ${TUNN_NAME} could be found in ${CONFIG_DIR}"

# Check interface status
INTERFACE=$(wg show $TUNN_NAME &>/dev/null)
RETURN_VALUE=$?

case "$RETURN_VALUE" in
  0) ;;
  1) die 2 "[CRITICAL] Interface ${TUNN_NAME} is down" ;;
  *) die 3 "[UNKNOWN] Check command exited with unhandled exit code";;
esac


# Exit normally
die 0 "[OK] WireGuard Interface ${TUNN_NAME} is up"
