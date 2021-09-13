#!/bin/bash

# This check validates access to public Canonical package repositories and third 
# party resources, such as archive.ubuntu.com, cloud-images.ubuntu.com, jaas.ai, etc.

# Based on check_sources.sh script by @msmarcal
# https://github.com/msmarcal/check_sources/blob/master/check_sources.sh

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

echo "This check validates access to public Canonical package" \
     "repositories and third party resources, such as" \
     "archive.ubuntu.com, cloud-images.ubuntu.com, jaas.ai, etc." \

http=(
ubuntu-cloud.archive.canonical.com
nova.cloud.archive.ubuntu.com
cloud.archive.ubuntu.com
nova.clouds.archive.ubuntu.com
clouds.archive.ubuntu.com
cloud-images.ubuntu.com
keyserver.ubuntu.com
archive.ubuntu.com
security.ubuntu.com
launchpad.net
jujucharms.com
streams.canonical.com
images.maas.io
packages.elastic.co
artifacts.elastic.co
packages.elasticsearch.org
)

https=(
cloud-images.ubuntu.com
keyserver.ubuntu.com
usn.ubuntu.com
launchpad.net
jujucharms.com
jaas.ai
charmhub.io
streams.canonical.com
snapcraft.io
images.maas.io
packages.elastic.co
artifacts.elastic.co
packages.elasticsearch.org
entropy.ubuntu.com
login.ubuntu.com
images.maas.io
api.jujucharms.com
api.snapcraft.io
livepatch.canonical.com
dashboard.snapcraft.io
image-registry.canonical.com
rocks.canonical.com
quay.io
gcr.io
k8s.gcr.io
storage.googleapis.com
auth.docker.io
)

echo ""
echo "Step 1 of 1: (Optional) Enter Proxy URL, e.g." \
    "http://user:password@proxy.example.com:3128/, or provide empty" \
    "value if proxy is not required for accessing external resources."

# Read Proxy URL from the console
read -p "Proxy URL: " proxy

echo ""

failed="false"
for protocol in http https
do
    sources="${protocol}[@]"
    for source in "${!sources}"
    do
        echo -n "Checking ${protocol}://${source}... "
        retcode=$(http_proxy=${proxy} https_proxy=${proxy} \
            wget --quiet --timeout 5 --server-response --no-check-certificate --spider \
            "${protocol}"://"${source}" 2>&1 | awk 'NR==1{print $2}' || echo $?)
        if [[ "${retcode}" =~ ^2.*|^3.*|^4.* ]]
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
    echo "Description: Checking access to public Canonical resources" \
         "failed. Possible reasons for this failure may include:"
    echo "- firewall rules do not allow this traffic,"
    echo "- DNS nameservers are down,"
    echo "- DNS nameservers could not be reached via default gateway."
    exit 1
fi
