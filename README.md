# Useful Scripts
---------------------------------------------------------------------------------------------------------
This repository was created as a source for all scripts developed and/or found useful by Accuris Technologies Ltd and it's subsidiaries.

**DISCLAIMER: IF LOGGED IN AS A NON-ROOT USER, DO NOT RUN THESE SCRIPTS USING THE "SUDO" COMMAND UNLESS OTHERWISE STATED. THESE SCRIPTS WILL AUTOMATICALLY CALL SUDO FOR COMMANDS THAT REQUIRE SUPERUSER PERMISSIONS TO RUN.**

## Scripts
### go-install.sh
This script will download, extract and install v1.16.5 of the [Go](https://golang.org/) binary onto a Linux system running the AMD64 kernel.

### debian10-bird2-install.sh
This script will automatically configure the required package repository as well as install the [BIRD2](https://bird.network.cz/) BGP daemon onto a system running Debian 10 Buster.

### bgpq4-install.sh
This script will compile, build and install the [bgpq4](https://github.com/bgp/bgpq4) binary from source.

### debian_ubuntu-pathvector-install.sh
This script will install the [Pathvector](https://pathvector.io) package from the Pathvector repository on systems running Debian or Ubuntu.

Before running `debian_ubuntu-pathvector-install.sh`, please ensure the following scripts are run in the order shown below:
* `go-install.sh`
* `debian10-bird2-install.sh` (if Debian 10)
* `bgpq4-install.sh`

### debian-speedtest-install.sh
This script will automatically configure the required package repository as well as install the official [Speedtest CLI](https://www.speedtest.net/apps/cli) binary onto a system running Debian.

### rhel-speedtest-install.sh
This script will automatically configure the required package repository as well as install the official [Speedtest CLI](https://www.speedtest.net/apps/cli) binary onto a system running a flavour of RedHat Enterprise Linux.

### virtualizor_pdns_install.sh
This script will automatically configure and install nameservers running PowerDNS on CentOS 7 to be used with the [Virtualizor Cloud Panel](https://www.virtualizor.com/).

### linux-amd64-node_exporter-install.sh
This script will download, extract and install the [Prometheus Node Exporter](https://github.com/prometheus/node_exporter) binary onto a Linux system running the AMD64 kernel as well as configure and install the applicable systemd service.