#!/bin/bash
set -e
CADDY_REVERSE_URL=$1
if [ -z "$1" ]; then
    echo "Usage: $0 <reverse_proxy_url>"
    exit 1
fi
# Caddy Installer for Ubuntu 24.04
# Update package list and install dependencies
sudo apt update && apt upgrade -y
sudo apt install gnupg curl apt-transport-https debian-keyring debian-archive-keyring -y
# Import Caddy GPG key and add repository
sudo curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

# Add Caddy repository to sources list
wget -qO - https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee /etc/apt/sources.list.d/caddy.list

# Install Caddy
sudo apt update
sudo apt install -y caddy

# Configure Caddy as a reverse proxy to localhost:8069
sudo bash -c 'cat > /etc/caddy/Caddyfile <<EOF
$CADDY_REVERSE_URL {
    tls info@wisegar.org
    reverse_proxy localhost:8069
}
EOF'

# Enable and start Caddy service
sudo systemctl enable --now caddy
sudo systemctl start caddy
sudo systemctl status caddy

echo "Caddy installed, configured as reverse proxy to localhost:8069, and running via systemd."