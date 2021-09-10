# Overview

This repository contains the scripts for creating a customized Ubuntu Desktop ISO
image used for validating the readiness for a HAP.

The image is provisioned with the tooling for running semi-automated checks, such as
default gateway accessibility check, Internet access accessibility check, etc.

# Required packages

The following packages are required to customize LiveCD: 

- build-essential
- xorriso
- isolinux

Install these packages with `sudo apt install build-essential xorriso isolinux`.

# Usage

There is a Makefile that defines all steps that need to be done in order to customize
the Ubuntu 18.04 LiveCD. 

## Customize LiveCD and create an ISO image

Simply run the following:

```shell
make
```

As as result, a customized image `ubuntu-desktop-pre-hap-validation.iso` will be
created. The image contains the launcher that will be executed when the user
logs into the system. The luncher will run all checks from the `checks-enabled` 
directory.

The ISO image should be burned into a USB thumb drive or configured as a virtual
CD/DVD device in BMC (iDRAC, CIMC, etc.).

### Launcher

The launcher (`pre-hap-validation.py`) executes all the files it can find in the 
`checks-enabled` directory. 

The files are executed in alphabetical order, so it is a good idea to prefix a filename
with a number, e.g. `120-check-mtu.sh`. Files in the `checks-enabled` directory can be
grouped in directories and subdirectories.

There are a few ready made checking scripts in a `checks-available` directory. Yes,
resemblance to how apache2 deals with available and enabled sites and modules is
intentional. 

If you want to use one of the checks from the `checks-available` directory, simply
create a symlink in a `checks-enabled` directory pointing to the available check from
`checks-available` directory, e.g.:

```shell
ln -sr checks-available/mandatory/010-check-ping-oam-gateway.sh \
    checks-enabled/010-check-ping-oam-gateway.sh
```

### Provide custom default values for checks

In order to provide custom default values for enabled checks, modify the 
`defaults.bashrc` file so that it matches your target environment. For example, you can 
preconfigure OAM network details as follows:

```shell
# CIDR of the OAM VLAN
export default_subnet="192.168.0.0/24"

# OAM default gateway
export default_gateway="192.168.0.1"

# OAM IPv4 address of the node
export default_ip="192.168.0.11"
```

Then run `make` again to re-provision the ISO image with your updates.

## Test the ISO image

Test newly created customized image with the following:

```shell
make test
```

## Clean up

Clean up temporary directories created during the process with:

```shell
make clean
```