#!/bin/bash

set -e

# Define variables used by odoo-18-ubuntu-installer.sh
export ODOO_DB="odoo_db"
export ODOO_PORT="8069"
export ODOO_ADMIN="admin"
export ODOO_PASSWORD="admin_password"
export ODOO_CONFIG="/etc/odoo/odoo.conf"
# Add any other variables required by odoo-18-ubuntu-installer.sh here

./postgres-ubuntu-installer.sh
./odoo-18-ubuntu-installer.sh
./caddy-ubuntu-installer.sh