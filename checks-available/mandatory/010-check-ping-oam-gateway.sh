#!/bin/bash

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

echo "Please provide the networking configuration for this machine."

echo ""
echo "Step 1 of 4: Select network device to be configured with IP" \
     "address from OAM network."
echo "Available devices:"

nics=$(ip -o link | grep -v " lo:" | cut -d " " -f 2 | sed 's/:$//' | sed 's/@.*$//')
for nic in $nics
do
    echo "  $nic"
    networkctl status --no-pager ${nic} 2> /dev/null | \
        egrep "(Speed|Model|Connected To)" | sed "s/^\s*/    /"
done

# Read name of the network device to be configured with IP address
# TODO: add validation of input value
until [ ! -z "${device}" ]
do
    if [ ! -z ${default_device} ]
    then
        read -p "Network device [${default_device}]: " device
        device=${device:-${default_device}}
    else
        read -p "Network device: " device
    fi
done

# TODO: add validation of input value
echo ""
echo "Step 2 of 4: Subnet for the OAM network, in CIDR format, e.g. 192.168.0.0/24."
until [ ! -z "${subnet}" ]
do
    if [ ! -z ${default_subnet} ]
    then
        read -p "Subnet [${default_subnet}]: " subnet
        subnet=${subnet:-${default_subnet}}
    else
        read -p "Subnet: " subnet
    fi
done

# TODO: add default choice, calculated based on $subnet (if historical entry does not exist)
# TODO: add validation of input value
echo ""
echo "Step 3 of 4: IP address of the default gateway for the OAM network, e.g. 192.168.0.1."
until [ ! -z "${gateway}" ]
do
    if [ ! -z ${default_gateway} ]
    then
        read -p "Gateway IP address [${default_gateway}]: " gateway
        gateway=${gateway:-${default_gateway}}
    else
        read -p "Gateway IP address: " gateway
    fi
done

# TODO: add default choice, calculated based on $subnet (if historical entry does not exist)
# TODO: add validation of input value
echo ""
echo "Step 4 of 4: Static IP address for this machine, e.g. 192.168.0.11."
until [ ! -z "${ip}" ]
do
    if [ ! -z ${default_ip} ]
    then
        read -p "IP address [${default_ip}]: " ip
        ip=${ip:-${default_ip}}
    else
        read -p "IP address: " ip
    fi
done

echo ""

# Save configuration
default_device=${device}
default_subnet=${subnet}
default_gateway=${gateway}
default_ip=${ip}
declare -p default_device default_subnet default_gateway default_ip > .$(basename $0)

# Remove any IP address that is assigned to device $device
echo -n "Removing existing IP address(es) from device ${device}... "
if ip address flush ${device}
then 
    echo_ok "OK"
else 
    echo_error "Failed"
fi

# Assign $ip to $device
echo -n "Configuring device ${device} with IP address ${ip}... "
if ip address add ${ip}/$(echo "${subnet}" | cut -d "/" -f 2) dev ${device}
then 
    echo_ok "OK"
else 
    echo_error "Failed"
fi

# Remove default gateway before setting up a new one
gateway_for_removal=$(ip route | grep default)
if [ ! -z "${gateway_for_removal}" ] ;
then
    existing_gateway_ip=$(echo "${gateway_for_removal}" | cut -d " " -f 3)
    echo -n "Removing existing default gateway ${existing_gateway_ip}... "
    if ip route del ${gateway_for_removal}
    then 
        echo_ok "OK"
    else
        echo_error "Failed"
    fi
fi

# Configure new default gateway
echo -n "Configuring default gateway with IP ${gateway}... "
if ip route add default via ${gateway} dev ${device}
then
    echo_ok "OK"
else 
    echo_error "Failed"
fi

echo -n "Pinging default gateway ${gateway}... "
if ping -c 3 ${gateway} &> /dev/null
then
    echo_ok "OK"
    echo ""
    echo -n "Test result: "
    echo_ok "Success"
    exit 0
else
    echo_error "Failed"
    echo ""
    echo -n "Test result: "
    echo_error "Failed"
    echo "Description: Default gateway does not respond to ICMP requests. It is" \
         "quite likely that the Internet access will not be available. Possible" \
         "reasons for this failure ma include:"
    echo "- default gateway has not been configured,"
    echo "- firewall rules do not allow ICMP traffic,"
    echo "- the switch expects bonded ports only,"
    echo "- provided IP address of the machine and / or gateway is incorrect,"
    echo "- provided subnet CIDR is incorrect."
    exit 1
fi