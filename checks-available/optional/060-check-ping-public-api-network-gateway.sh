#!/bin/bash

# This check validates access to the OpenStack Public API network gateway. The
# gateway must be accessible from the OAM network; it is necessary for accessing
# OpenStack API in order to run tests.
# This check tries to ping a specified IP address.
#
# Defaults:
# default_os_api_gateway
#   IP address of the OpenStack Public API network gateway, e.g. 192.168.20.1.

# Color definitions
GREEN='\033[0;32m'
RED='\e[31m'
RESET='\033[0m'

# Print green status code
function echo_ok() {
    printf "${GREEN}%s %s${RESET}\\n" "${1}"
}

# Print red status code
function echo_error() {
    printf "${RED}%s %s${RESET}\\n" "${1}"
}

# Source stored configuration
if [ -f ".$(basename $0)" ]; then
  source ".$(basename $0)"
fi

echo "This check validates access to the OpenStack Public API network gateway. The" \
     "gateway must be accessible from the OAM network; it is necessary for accessing" \
     "OpenStack API in order to run tests." \
     "This check tries to ping a specified IP address."

echo ""
echo "Step 1 of 1: Enter IP address of the OpenStack Public API network gateway," \
     "e.g. 192.168.20.1."

# Read IP address of the OpenStack Public API network gateway from the console
until [ ! -z "${os_api_gateway}" ]
do
    if [ ! -z "${default_os_api_gateway}" ]
    then
        read -p "OpenStack Public API network gateway [${default_os_api_gateway}]: " os_api_gateway
        os_api_gateway=${os_api_gateway:-${default_os_api_gateway}}
    else
        read -p "OpenStack Public API network gateway: " os_api_gateway
    fi
done

# Save configuration
default_os_api_gateway=${os_api_gateway}
declare -p default_os_api_gateway > .$(basename $0)

echo ""

failed="false"
echo -n "Checking access to ${os_api_gateway} ... "
if ping -c 3 ${os_api_gateway} &> /dev/null 
then
    echo_ok "OK"
else
    echo_error "Failed"
    failed="true"
fi

echo ""

if [[ "${failed}" == "false" ]]
then
    echo -n "Test result: "
    echo_ok "Success"
    exit 0
else
    echo -n "Test result: "
    echo_error "Failed"
    echo "Description: Checking access to OpenStack Public API network gateway" \
         "failed. Possible reasons for this failure may include:"
    echo "- the gateway is not configured,"
    echo "- the routing between OAM and OpenStack Public API network is not configured,"
    echo "- firewall does not allow ICMP traffic ."
    exit 1
fi
