#!/bin/bash
# Odoo 18 Installer for Ubuntu 24.04

set -e

ODOO_VERSION="18.0"
ODOO_USER="odoo"
ODOO_HOME="/opt/odoo"
ODOO_CONF="/etc/odoo.conf"
ODOO_PORT="8069"
PG_VERSION="16"

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y python3 python3-pip python3-venv build-essential wget git \
    python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev \
    libjpeg-dev libpq-dev libffi-dev libssl-dev libmysqlclient-dev \
    nodejs npm libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev \
    libwebp-dev libharfbuzz-dev libfribidi-dev libtiff5-dev libopenjp2-7-dev

echo "Installing PostgreSQL..."
sudo apt install -y postgresql-$PG_VERSION

echo "Creating Odoo PostgreSQL user..."
sudo -u postgres createuser --createdb --username postgres --no-createrole --no-superuser $ODOO_USER || true

echo "Creating Odoo system user..."
sudo adduser --system --home=$ODOO_HOME --group $ODOO_USER || true

echo "Cloning Odoo $ODOO_VERSION..."
sudo git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git $ODOO_HOME

echo "Creating Python virtual environment..."
sudo -u $ODOO_USER python3 -m venv $ODOO_HOME/venv

echo "Installing Python requirements..."
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install wheel
sudo -u $ODOO_USER $ODOO_HOME/venv/bin/pip install -r $ODOO_HOME/requirements.txt

echo "Installing wkhtmltopdf..."
sudo apt install -y wkhtmltopdf

echo "Creating Odoo configuration file..."
sudo tee $ODOO_CONF > /dev/null <<EOF
[options]
; This is the Odoo configuration file
admin_passwd = admin
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False
addons_path = $ODOO_HOME/addons
logfile = /var/log/odoo/odoo.log
xmlrpc_port = $ODOO_PORT
EOF

sudo chown $ODOO_USER:$ODOO_USER $ODOO_CONF

echo "Creating log directory..."
sudo mkdir -p /var/log/odoo
sudo chown $ODOO_USER:$ODOO_USER /var/log/odoo

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

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and starting Odoo..."
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

echo "Odoo $ODOO_VERSION installation complete!"
echo "Access Odoo at http://<your-server-ip>:$ODOO_PORT"