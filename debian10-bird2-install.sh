#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

${SUDO} curl -sSL -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
${SUDO} sh -c 'echo "deb http://bird.network.cz/debian/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/bird.list'
${SUDO} apt-get update
${SUDO} apt-get -y install bird2
${SUDO} systemctl enable bird
${SUDO} systemctl start bird