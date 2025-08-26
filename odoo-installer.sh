#!/bin/bash
# Odoo 18 Installer for Ubuntu 24.04
set -e
ODOO_VERSION="18.0"
ODOO_USER=$1
ODOO_HOME="/opt/odoo"
ODOO_CUSTOMS="$ODOO_HOME/customs"
ODOO_ADDONS="$ODOO_HOME/addons"
ODOO_CONF="/etc/odoo.conf"
ODOO_DB_PORT="5432"
ODOO_DB_HOST="localhost"
ODOO_DB_NAME=$2
ODOO_DB_PASSWORD=$3
ODOO_PORT=$4
PG_ADMIN_PASSWORD=$5
ODOO_URL=$6
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ]; then
    echo "Usage: $0 <odoo_user> <odoo_db_name> <odoo_db_password> <odoo_port> <postgres_password> <odoo_url>"
    exit 1
fi
echo "ODOO_VERSION: $ODOO_VERSION"
echo "ODOO_USER: $ODOO_USER"
echo "ODOO_DB_NAME: $ODOO_DB_NAME"
echo "ODOO_DB_PASSWORD: $ODOO_DB_PASSWORD"
echo "ODOO_PORT: $ODOO_PORT"
echo "PG_ADMIN_PASSWORD: $PG_ADMIN_PASSWORD"
echo "ODOO_URL: $ODOO_URL"

echo #---------------------------------------------------------------------------------
echo "Install PostgreSQL and create Odoo database user"
wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/postgres-ubuntu-installer.sh
sudo sh postgres-ubuntu-installer.sh "16" "$PG_ADMIN_PASSWORD"
echo #---------------------------------------------------------------------------------
echo "Install ODOO"
wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/odoo-ubuntu-installer.sh
sudo sh odoo-ubuntu-installer.sh "$ODOO_USER" "$ODOO_DB_NAME" "$ODOO_DB_PASSWORD" "$ODOO_PORT"
echo #---------------------------------------------------------------------------------
echo "Install CADDY"
wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/caddy-ubuntu-installer.sh
sudo sh caddy-ubuntu-installer.sh "$ODOO_URL" "$ODOO_PORT"
echo #--------------------------------------------------------------------------------- 
echo "Odoo $ODOO_VERSION installation completed."


