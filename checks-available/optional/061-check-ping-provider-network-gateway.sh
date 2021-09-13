#!/bin/bash

# This check validates access to the Provider network gateway. The gateway must be 
# accessible from the OAM network; it is necessary for accessing VMs with Floating 
# IPs assigned in order to run tests.
# This check tries to ping a specified IP address.
#
# Defaults: 
# default_provider_gateways
#   space separated list of IP addresses for the provider network gateway(s), 
#   e.g. '172.27.1.1 172.17.2.1'.

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

echo "This check validates access to the Provider network gateway. The" \
     "gateway must be accessible from the OAM network; it is necessary for accessing" \
     "VMs with Floating IPs assigned in order to run tests." \
     "This check tries to ping a specified IP address."

echo ""
echo "Step 1 of 1: Enter space separated list of IP addresses for the provider" \
     "network gateway(s), e.g. '172.27.1.1 172.17.2.1'."

# Read IP addresses of the Provider networks' gateways from the console
until [ ! -z "${provider_gateways}" ]
do
    if [ ! -z "${default_provider_gateways}" ]
    then
        read -p "Provider network gateway(s) [${default_provider_gateways}]: " provider_gateways
        provider_gateways=${provider_gateways:-${default_provider_gateways}}
    else
        read -p "Provider network gateway(s): " provider_gateways
    fi
done

# Save configuration
default_provider_gateways=${provider_gateways}
declare -p default_provider_gateways > .$(basename $0)

echo ""

failed="false"
for provider_gateway in ${provider_gateways}
do
    echo -n "Checking access to ${provider_gateway} ... "
    if ping -c 3 ${provider_gateway} &> /dev/null 
    then
        echo_ok "OK"
    else
        echo_error "Failed"
        failed="true"
    fi
done

echo ""

if [[ "${failed}" == "false" ]]
then
    echo -n "Test result: "
    echo_ok "Success"
    exit 0
else
    echo -n "Test result: "
    echo_error "Failed"
    echo "Description: Checking access to Provider network gateway" \
         "failed. Possible reasons for this failure may include:"
    echo "- the gateway is not configured,"
    echo "- the routing between OAM and Provider networks is not configured,"
    echo "- firewall does not allow ICMP traffic ."
    exit 1
fi
