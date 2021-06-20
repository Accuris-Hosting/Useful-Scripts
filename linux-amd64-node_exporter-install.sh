#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

echo "Changing directory to /tmp..."
cd /tmp
echo "Downloading node_exporter binary..."
wget https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz
echo "Extracting node_exporter tarball..."
${SUDO} tar -xzf /tmp/node_exporter-1.1.2.linux-amd64.tar.gz
echo "Copying node_exporter executable for systenm-wide use..."
${SUDO} cp /tmp/node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/sbin
echo "Creating systemd service..."
wget https://raw.githubusercontent.com/Accuris-Hosting/Useful-Scripts/master/systemd-service-files/node_exporter.service
${SUDO} mv /tmp/node_exporter.service /etc/systemd/system/
${SUDO} chown root:root /etc/systemd/system/node_exporter.service
echo "Starting and enabling systemd service..."
${SUDO} systemctl daemon-reload
${SUDO} systemctl start node_exporter.service
${SUDO} systemctl enable node_exporter.service
echo "Removing tarball and other unneeded files..."
cd /tmp
rm -rf /tmp/node_exporter-1.1.2.linux-amd64.tar.gz
rm -rf /tmp/node_exporter-1.1.2.linux-amd64
echo "node_exporter installation completed successfully!"
exit