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

# Source stored configuration
if [ -f ".$(basename $0)" ]; then
  source ".$(basename $0)"
fi

echo "This check validates access to provided DNS nameservers."

echo ""
echo "Step 1 of 2: Enter all DNS nameservers separated by space, e.g." \
     "'192.168.10.10 192.168.10.11'"

# Read DNS nameservers' IPs from the console
until [ ! -z "${dns_nameservers}" ]
do
    if [ ! -z "${default_dns_nameservers}" ]
    then
        read -p "DNS Nameservers [${default_dns_nameservers}]: " dns_nameservers
        dns_nameservers=${dns_nameservers:-${default_dns_nameservers}}
    else
        read -p "DNS Nameservers: " dns_nameservers
    fi
done

echo ""
echo "Step 2 of 2: Enter all domains to test DNS resolution, separated by space," \
     "e.g. 'archive.ubuntu.com images.maas.io'."

# Populate default value from stored configuration or use provided defaults
default_domains=${default_domains:-'archive.ubuntu.com images.maas.io'}

# Read domains from the console
read -p "Domains [${default_domains}]: " domains
domains=${domains:-${default_domains}}

echo ""

# Save configuration
default_dns_nameservers=${dns_nameservers}
default_domains=${domains}
declare -p default_dns_nameservers default_domains > .$(basename $0)

# Configure DNS nameservers for the default interface
interface=$(ip route | grep default | awk '{print $5}')
printf -v set_dns_option ' --set-dns %s' ${dns_nameservers}
echo -n "Configuring DNS Nameservers ${dns_nameservers} for" \
    "interface ${interface}... "
if systemd-resolve ${set_dns_option} --interface ${interface} &> /dev/null
then 
    echo_ok "OK"
else 
    echo_error "Failed"
fi

# Test DNS resolution
failed="false"
for dns_nameserver in ${dns_nameservers}
do
    for domain in ${domains}
    do
        echo -n "Querying ${dns_nameserver} for ${domain} ... "
        if dig ${domain} @${dns_nameserver} | grep NOERROR 1>/dev/null
        then
            echo_ok "OK"
        else
            echo_error "Failed"
            failed="true"
        fi
    done
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
    echo "Description: DNS resolution failed." \
         "Possible reasons for this failure may include:"
    echo "- DNS nameservers provided are incorrect,"
    echo "- firewall rules do not allow this traffic,"
    echo "- DNS nameservers are down,"
    echo "- DNS nameservers could not be reached via default gateway."
    echo "You can troubleshoot this problem with 'dig' utility," \
         "running for example 'dig ${domain} @${dns_nameserver}' and" \
         "observing the result."
    exit 1
fi
