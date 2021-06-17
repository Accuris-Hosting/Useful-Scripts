#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

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
exit