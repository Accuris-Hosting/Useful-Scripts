#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

echo "Starting Pathvector install"
${SUDO} bash -c "curl https://repo.pathvector.io/pgp.asc > /usr/share/keyrings/pathvector.asc"
${SUDO} bash -c "echo 'deb [signed-by=/usr/share/keyrings/pathvector.asc] https://repo.pathvector.io/apt/ stable main' > /etc/apt/sources.list.d/pathvector.list"
${SUDO} apt-get update
${SUDO} apt-get install -y pathvector
source /etc/profile
echo "Pathvector installation completed successfully!"
exit