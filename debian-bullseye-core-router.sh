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
echo "Go installation completed successfully!"
echo "Sleeping for 5 seconds before proceeding"
sleep 5
echo "Adding Bullseye-Backports repository..."
${SUDO} cat << EOF > /etc/apt/sources.list.d/bullseye-backports.list
deb http://deb.debian.org/debian bullseye-backports main contrib non-free
deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free
EOF
echo "Updating system package cache..."
${SUDO} apt update
echo "Installing BIRD2..."
${SUDO} apt -t bullseye-backports -y install bird2
echo "Enabling BIRD2 systemd service..."
${SUDO} systemctl enable bird
echo "Starting BIRD2 systemd service..."
${SUDO} systemctl start bird
echo "BIRD2 installation completed successfully!"
echo "Sleeping for 5 seconds before proceeding"
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
echo "Sleeping for 5 seconds before proceeding"
sleep 5
echo "Starting Pathvector install"
${SUDO} bash -c "curl https://repo.pathvector.io/pgp.asc > /usr/share/keyrings/pathvector.asc"
${SUDO} bash -c "echo 'deb [signed-by=/usr/share/keyrings/pathvector.asc] https://repo.pathvector.io/apt/ stable main' > /etc/apt/sources.list.d/pathvector.list"
${SUDO} apt-get update
${SUDO} apt-get install -y pathvector
source /etc/profile
echo "Pathvector installation completed successfully!"
exit