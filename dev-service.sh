#!/bin/sh

# This script stops a systemd-managed OpenStack service on an 'installed'
# system and runs the same service from a git checkout using system config and
# libraries.
#
# To use it:
#
# * Create a development user on the target machine
# * Ensure you've set mode o+x (e.g. 0751) on the user's home directory
# * Ensure the development user is permitted to use sudo to execute commands as
#   service users (e.g. nova).
# * Check out the openstack component in the user's home directory. Ensure that
#   the git checkout is in a directory with the same name as the component
#   (e.g. 'nova'), which it will be by default.
# * run: $ dev-service.sh <component> <sub-component>
#   e.g.: $ dev-service.sh nova compute
#
# GOTCHA: If you haven't set o+x on the user's home directory, everything will
# *APPEAR* to be working correctly, but it will actually still be running the
# system-installed version. I normally insert a syntax error into the git
# checkout and observe it fail at least once to double check everything is
# correctly configured.
#
# The service will run in the foreground. It can be killed with Ctrl-C. If the
# systemd service was running when dev-service.sh was executed it will be
# stopped first, and automatically restarted when dev-service.sh exits.

component=$1
sub=$2


if [ -z "$component" -o -z "$sub" ]; then
    echo "You must specify an openstack service and sub-component"
    echo "e.g. nova compute"
    exit 1
fi

service="$component-$sub"
systemd_service="openstack-$service"

function restart_service() {
    sudo systemctl start "$systemd_service"
}

status=$(systemctl is-active "$systemd_service")
if [ "$status" == "active" ]; then
    sudo systemctl stop "$systemd_service"
    trap restart_service EXIT
elif [ "$status" != "inactive" ]; then
    echo "$systemd_service is not a valid systemd unit"
    exit 1
fi

sudo PYTHONPATH=$HOME/$component -u $component -- "$service"
