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
wget https://golang.org/dl/go1.16.6.linux-amd64.tar.gz
echo "Removing previous go installations"
${SUDO} rm -rf /usr/local/go
echo "Extracting go binary"
${SUDO} tar -C /usr/local -xzf /tmp/go1.16.6.linux-amd64.tar.gz
echo "Adding /usr/local/go/bin to the PATH environment variable"
${SUDO} sh -c 'echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile'
echo "Removing tarball"
cd /tmp
rm -rf /tmp/go1.16.6.linux-amd64.tar.gz
echo "Go installation completed successfully!"
sleep 5
echo "Starting bgpq4 install"
echo "Changing directory to /tmp"
cd /tmp
echo "Cloning bgpq4 GitHub repository"
git clone https://github.com/bgp/bgpq4.git
echo "Changing into the bgpq4 source directory"
cd /tmp/bgpq4/
echo "Preparing the build system"
./bootstrap
echo "Compiling the software: Step 1/3  - Configure"
./configure
echo "Compiling the software: Step 2/3 - Creating install file"
make
echo "Compiling the software: Step 3/3 - Installing software"
${SUDO} make install
echo "Deleting temp build directory"
cd /tmp
rm -rf /tmp/bgpq4/
echo "bgpq4 installation completed successfully!"
sleep 5
echo "Starting pathvector install"
echo "Changing to home directory"
cd $HOME/
echo "Cloning pathvector GitHub repository"
git clone https://github.com/natesales/pathvector.git
echo "Changing into the pathvector source directory"
cd $HOME/pathvector/
echo "Generating code"
go generate
echo "Building pathvector"
go build
echo "Copying pathvector executable for systenm-wide use"
${SUDO} cp $HOME/pathvector/pathvector /usr/local/sbin
echo "Creating runtine configuration cache directory"
${SUDO} mkdir -p /var/run/pathvector/cache/
echo "Deleting temp build directory"
cd $HOME/
rm -rf $HOME/pathvector
echo "pathvector installation completed successfully!"
exit