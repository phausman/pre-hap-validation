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

echo $default_url

# Source stored configuration
if [ -f ".$(basename $0)" ]; then
    source ".$(basename $0)"
fi

echo "This is an example check, validating the access to a given" \
     "URL. The user is prompted for the URL and then the script" \
     "tries to connect to this URL."

echo ""
echo "Step 1 of 1: Enter URL that will be checked, e.g. https://ubuntu.com/"

# Populate default value from stored configuration or use provided defaults
default_url=${default_url:-'https://ubuntu.com/'}

# Read URL from the console
read -p "URL [${default_url}]: " url
url=${url:-${default_url}}

echo ""

# Save configuration
default_url=${url}
declare -p default_url > .$(basename $0)

echo -n "Checking access to ${url}... "
failed="false"
retcode=$(wget --quiet --timeout 5 --server-response --no-check-certificate --spider \
    "${url}" 2>&1 | awk 'NR==1{print $2}' || echo $?)
if [[ "${retcode}" =~ ^2.*|^3.*|^4.* ]]
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
    echo "Description: URL ${url} cannot be accessed." \
         "Possible reasons for this failure may include:"
    echo "- provided URL is incorrect,"
    echo "- firewall rules do not allow this traffic,"
    echo "- website is not available,"
    echo "- DNS nameserver is not able to resolve IP address."
    exit 1
fi
