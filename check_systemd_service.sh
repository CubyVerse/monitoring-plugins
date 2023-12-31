#!/usr/bin/env bash

# Source: https://github.com/patrikskrivanek/icinga2-check_systemd_service/

VERSION='v1.1.0'
RELEASE_DATE='2019-08-13'

# output codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

PROGRAM=`basename "$0"`

#print help function
print_help() {
    echo -n "This plugin checks status of systemd service and also can restart service if is not running.
Returns exit codes based on nagios plugin api standard.
Usage:
    $PROGRAM [OPTION]
Options:
    [service]           name of systemd service for check
    --restart           restart service if is not running
    -V, --version       current version of plugin
    -h, --help          plugin help and usage
Examples:
    $PROGRAM apache2
    $PROGRAM cron --restart
    $PROGRAM mysql
    $PROGRAM -V
    $PROGRAM --help
version: $VERSION
release: $RELEASE_DATE
"

    exit 0
}

#print version function
print_version() {
    echo "$VERSION"
    exit 0
}

# check "zero" param
([[ -z "$1" ]]) && print_help

case "$1" in
    -h|--help)
    print_help
    ;;
    -V|--version)
    print_version
    ;;
    *)
    service="$1"
    ;;
esac

# arg shift
POSITIONAL=()
while [[ $# -gt 0 ]]
do

case "$2" in
    --reload)
    RELOAD=YES
    shift
    ;;
    --restart)
    RESTART=YES
    shift
    ;;
    *)
    # unknown option, save
    POSITIONAL+=("$2")
    shift
    ;;
esac

done

# restore positional parameters
set -- "${POSITIONAL[@]}"

# service check
if [[ -z "$service" ]]; then
    echo "WARNING: service name hasn't been set"
    exit $STATE_WARNING
fi

status=$(systemctl is-enabled $service 2>/dev/null)
ret=$?

# service does not exist
if [[ -z "$status" ]]; then
    echo "ERROR: service $service doesn't exist"
    exit $STATE_CRITICAL
fi

# alternative state
if [[ $ret -ne 0 ]]; then
    echo "ERROR: service $service is $status"
    exit $STATE_CRITICAL
fi

# check if is or is not running
systemctl --quiet is-active $service

if [[ $? -ne 0 ]]; then
    if [[ ! -z "$RESTART" ]]; then
        systemctl restart $service

        if [[ "$?" -eq 0 ]]; then
            echo "OK: service restarted"
            exit $STATE_OK
        else
            echo "ERROR: service restart failed"
            exit $STATE_CRITICAL
        fi
    else
        echo "ERROR: service $service is not running"
        exit $STATE_CRITICAL
    fi
else
    echo "OK: service $service is running"
    exit $STATE_OK
fi
