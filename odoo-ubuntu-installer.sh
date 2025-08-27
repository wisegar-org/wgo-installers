#!/bin/bash
# Odoo 18 Installer for Ubuntu 24.04
set -e
ODOO_VERSION="18.0"
ODOO_USER=$1
ODOO_HOME="/opt/odoo/$ODOO_INSTALL_NAME"
ODOO_CUSTOMS="$ODOO_HOME/customs"
ODOO_ADDONS="$ODOO_HOME/addons"
ODOO_CONF="/etc/$ODOO_INSTALL_NAME-odoo.conf"
ODOO_DB_PORT="5432"
ODOO_DB_HOST="localhost"
ODOO_DB_NAME=$2
ODOO_DB_PASSWORD=$3
ODOO_PORT=$4
ODOO_INSTALL_NAME=$5

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ||  [ -z "$4" ] ; then
    echo "Usage: $0 <odoo_user> <odoo_db_name> <odoo_db_password> <odoo_port> <installation name - optional>"
    exit 1
fi
echo "ODOO_VERSION: $ODOO_VERSION"
echo "ODOO_USER: $ODOO_USER"
echo "ODOO_DB_NAME: $ODOO_DB_NAME"
echo "ODOO_DB_PASSWORD: $ODOO_DB_PASSWORD"
echo "ODOO_PORT: $ODOO_PORT"

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

echo DB User and DB Creation for Odoo 
echo  Create custom $ODOO_USER with password
sudo -u postgres psql -c "CREATE USER $ODOO_USER WITH ENCRYPTED  PASSWORD '$ODOO_DB_PASSWORD';"
sudo -u postgres psql -c "ALTER USER $ODOO_USER WITH SUPERUSER;"

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
db_name = False
addons_path = $ODOO_HOME/addons,$ODOO_HOME/customs/addons
logfile = /var/log/odoo/$ODOO_INSTALL_NAME-odoo.log
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
Description=Odoo ERP Service - $ODOO_INSTALL_NAME
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

sudo ufw allow 22
sudo ufw allow $ODOO_PORT
sudo ufw enable
sudo ufw reload

echo "Reloading systemd and starting Odoo..."
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

echo "Odoo $ODOO_VERSION installation complete!"
echo "Access Odoo at http://<your-server-ip>:$ODOO_PORT"
