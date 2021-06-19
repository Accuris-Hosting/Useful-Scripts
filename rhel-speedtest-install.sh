#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

echo "Changing to home directory..."
cd $HOME/
echo "Downloading official Speedtest-CLI install script..."
wget https://install.speedtest.net/app/cli/install.rpm.sh
echo "Granting execute (+x) permissions to official Speedtest-CLI setup script..."
${SUDO} chmod +x $HOME/install.rpm.sh
echo "Running official Speedtest-CLI setup script..."
${SUDO} bash $HOME/install.rpm.sh
echo "Downloading and installing official Speedtest-CLI package..."
${SUDO} yum install -y speedtest
echo "Deleting install script..."
cd $HOME/
rm $HOME/install.rpm.sh
echo "Official Speedtest-CLI package installation completed successfully!"
exit