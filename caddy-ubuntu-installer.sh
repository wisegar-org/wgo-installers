#!/bin/bash
set -e
CADDY_REVERSE_URL=$1
CADDY_REVERSE_PORT=$2
if [ -z "$1" ] || [ -z "$0" ]; then
    echo "Usage: $0 <caddy_reverse_proxy_url> <caddy_reverse_proxy_port>"
    exit 1
fi

echo "CADDY_REVERSE_URL: $CADDY_REVERSE_URL"
echo "CADDY_REVERSE_PORT: $CADDY_REVERSE_PORT"

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
sudo mv /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
$CADDY_REVERSE_URL {
    tls info@wisegar.org
    reverse_proxy localhost:$CADDY_REVERSE_PORT
}
EOF

sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
sudo ufw reload

# Enable and start Caddy service
sudo systemctl enable --now caddy
sudo systemctl start caddy
sudo systemctl status caddy

echo "Caddy installed, configured as reverse proxy to localhost:8069, and running via systemd."