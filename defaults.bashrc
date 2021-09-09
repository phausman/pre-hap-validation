#
# 010-check-ping-oam-gateway.sh
#

# NIC that should be configured with OAM IP address, e.g. "eno1".
export default_device="ens3"

# CIDR of the OAM VLAN, e.g. "192.168.0.0/24".
export default_subnet="10.0.2.0/24"

# OAM default gateway, e.g. "192.168.0.1".
export default_gateway="10.0.2.2"

# OAM IPv4 address of the node, e.g. "192.168.0.11".
export default_ip="10.0.2.199"


#
# 030-check-dns-resolution.sh
#

# Space separated list of DNS Nameservers, e.g. "8.8.8.8 1.1.1.1"
export default_dns_nameservers="8.8.8.8 1.1.1.1"

# Space separated list of domains that should be used for testing
# DNS resolution, e.g. "archive.ubuntu.com images.maas.io".
export default_domains="archive.ubuntu.com"


#
# 050-check-ipmi-access.sh
#

# Space separated list of BMC IPs that should be used for testing
# for IPMI access.
export default_bmcs="192.168.22.22"