#!/bin/bash
# Odoo 18 Installer for Ubuntu 24.04

set -e
ODOO_VERSION="18.0"
ODOO_USER="odoo"
ODOO_HOME="/opt/odoo"
ODOO_CUSTOMS="$ODOO_HOME/customs"
ODOO_ADDONS="$ODOO_HOME/addons"
ODOO_CONF="/etc/odoo.conf"
ODOO_PORT="8069"
ODOO_DB_PORT="5432"
ODOO_DB_HOST="localhost"
ODOO_DB_NAME="odoo"
ODOO_DB_PASSWORD="odoo"
PG_VERSION="16"
PG_PASSWORD="postgres"

# Install prerequisites
sudo apt update
sudo apt install -y wget gnupg2 lsb-release

# Add PostgreSQL APT repository
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# Install PostgreSQL
sudo apt update
sudo apt install -y postgresql-$PG_VERSION

# Change postgres user password to 'postgres'
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$PG_PASSWORD';"

# Create user 'odoo' with password 'odoo'
sudo -u postgres psql -c "CREATE USER $ODOO_USER WITH PASSWORD '$ODOO_DB_PASSWORD';"

# Create database 'odoo' owned by 'odoo' user
sudo -u postgres psql -U postgres -c "CREATE DATABASE odoo OWNER odoo;"

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/;s/^listen_addresses = 'localhost'/listen_addresses = '*'/;" /etc/postgresql/16/main/postgresql.conf

# Allow remote connections in pg_hba.conf
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
echo "host    all             all             ::/0                    md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

echo "PostgreSQL 16 installed, 'postgres' and 'odoo' users configured, and remote access enabled."

# ---------------------------------------------------------------------------------
echo "Installing Odoo $ODOO_VERSION..."
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y python3 python3-pip python3-venv build-essential wget git \
    python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev \
    libjpeg-dev libpq-dev libffi-dev libssl-dev libmysqlclient-dev \
    nodejs npm libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev \
    libwebp-dev libharfbuzz-dev libfribidi-dev libtiff5-dev libopenjp2-7-dev

echo "Creating Odoo system user..."
sudo adduser --system --home=$ODOO_HOME --group $ODOO_USER || true

echo "Cloning Odoo $ODOO_VERSION..."
sudo git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git $ODOO_HOME

echo "Creating Python virtual environment..."
sudo -u $ODOO_USER python3 -m venv $ODOO_HOME/venv

echo "Installing Python requirements..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install wheel
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install -r $ODOO_HOME/requirements.txt
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install rl-renderPM

echo "Installing wkhtmltopdf..."
sudo apt install -y wkhtmltopdf

echo "Creating Odoo configuration file..."
sudo tee $ODOO_CONF > /dev/null <<EOF
[options]
; This is the Odoo configuration file
admin_passwd = admin
db_host = $ODOO_DB_HOST
db_port = $ODOO_DB_PORT
db_user = $ODOO_USER
db_password = $ODOO_DB_PASSWORD
db_name = $ODOO_DB_NAME
addons_path = $ODOO_HOME/addons,$ODOO_HOME/customs/addons
logfile = /var/log/odoo/odoo.log
xmlrpc_port = $ODOO_PORT
EOF

sudo chown $ODOO_USER:$ODOO_USER $ODOO_CONF

echo "Creating log directory..."
sudo mkdir -p /var/log/odoo
sudo chown $ODOO_USER:$ODOO_USER /var/log/odoo

echo "Creating custom addons directory..."
sudo mkdir -p $ODOO_HOME/customs/addons

echo "Creating systemd service..."
sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
[Unit]
Description=Odoo ERP
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$ODOO_HOME/venv/bin/python3 $ODOO_HOME/odoo-bin -c $ODOO_CONF
StandardOutput=journal+console
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and starting Odoo..."
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

echo "Odoo $ODOO_VERSION installation complete!"
echo "Access Odoo at http://<your-server-ip>:$ODOO_PORT"

# ---------------------------------------------------------------------------------
# Caddy installation and configuration

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
studiomaggio.wisegar.org {
    tls info@wisegar.org
    reverse_proxy localhost:8069
}
EOF'

# Enable and start Caddy service
sudo systemctl enable --now caddy
sudo systemctl start caddy
sudo systemctl status caddy

echo "Caddy installed, configured as reverse proxy to localhost:8069, and running via systemd."