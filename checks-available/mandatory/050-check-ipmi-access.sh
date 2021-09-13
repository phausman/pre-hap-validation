#!/bin/bash

# This check validates access to the BMC controllers of the cloud nodes.
# It tries to run ipmi-ping against specified IP addresses.
#
# Defaults:
# default_bmcs
#   Space separated list of IP addresses of the BMC controllers of the cloud nodes, 
#   e.g. '192.168.1.10 192.168.1.11'.

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

echo "This check validates access to the BMC controllers of the cloud nodes." \
     "It tries to run ipmi-ping against specified IP addresses."

echo ""
echo "Step 1 of 1: Enter one or more IP addresses of the BMC controllers of the" \
     "cloud nodes. You can provide multiple space-separated IP addresses, e.g." \
     "'192.168.1.10 192.168.1.11'."

# Read BMC IP addresses from the console
until [ ! -z "${bmcs}" ]
do
    if [ ! -z "${default_bmcs}" ]
    then
        read -p "BMC IP address(es) [${default_bmcs}]: " bmcs
        bmcs=${bmcs:-${default_bmcs}}
    else
        read -p "BMC IP address(es): " bmcs
    fi
done

# Save configuration
default_bmcs=${bmcs}
declare -p default_bmcs > .$(basename $0)

echo ""

failed="false"
for bmc in ${bmcs}
do
    echo -n "Checking access to ${bmc} ... "
    if ipmi-ping -c 3 ${bmc} &> /dev/null 
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
    echo "Description: Checking access to BMC(s) failed." \
         "Possible reasons for this failure may include:"
    echo "- IPMI over LAN not enabled on the cloud nodes,"
    echo "- Out of Band (OOB) network could not be reached via default gateway,"
    echo "- firewall does not allow IPMI over LAN traffic (UDP, port 623)."
    exit 1
fi
