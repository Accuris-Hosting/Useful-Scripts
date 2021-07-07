#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

echo "Adding BIRD2 package repository to system..."
${SUDO} sh -c 'echo "deb [arch=amd64] http://provo-mirror.opensuse.org/repositories/home:/CZ-NIC:/bird-latest/Debian_10/  ./" > /etc/apt/sources.list.d/bird2.list'
${SUDO} cat << EOF > /etc/apt/preferences.d/bird2
Package: bird*
Pin: origin provo-mirror.opensuse.org
Pin-Priority: 600
EOF
echo "Installing prerequisite packages"
${SUDO} apt install -y gnupg2
echo "Adding repo signing keys"
${SUDO} apt-key adv --fetch-keys 'https://download.opensuse.org/repositories/home:/CZ-NIC:/bird-latest/Debian_10/Release.key'
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