#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

echo "Downloading BIRD2 GPG key..."
${SUDO} curl -sSL -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "Adding BIRD2 package repository to system..."
${SUDO} sh -c 'echo "deb http://bird.network.cz/debian/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/bird.list'
echo "Updating system package cache..."
${SUDO} apt-get update
echo "Installing BIRD2..."
${SUDO} apt-get -y install bird2
echo "Enabling BIRD2 systemd service"
${SUDO} systemctl enable bird
echo "Starting BIRD2 systemd service"
${SUDO} systemctl start bird
echo "BIRD2 installation completed successfully!"
exit