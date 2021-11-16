#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

echo "Starting Go install"
echo "Changing directory to /tmp"
cd /tmp
echo "Downloading go binary"
wget https://golang.org/dl/go1.17.3.linux-amd64.tar.gz
echo "Removing previous go installations"
${SUDO} rm -rf /usr/local/go
echo "Extracting go binary"
${SUDO} tar -C /usr/local -xzf /tmp/go1.17.3.linux-amd64.tar.gz
echo "Adding /usr/local/go/bin to the PATH environment variable"
${SUDO} sh -c 'echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile'
echo "Removing tarball"
cd /tmp
rm -rf /tmp/go1.17.3.linux-amd64.tar.gz
source /etc/profile
${SUDO} source /etc/profile
echo "Go installation completed successfully!"
exit