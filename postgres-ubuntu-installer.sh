#!/bin/bash
set -e

# Install prerequisites
sudo apt update
sudo apt install -y wget gnupg2 lsb-release

# Add PostgreSQL APT repository
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# Install PostgreSQL 16
sudo apt update
sudo apt install -y postgresql-16

# Change postgres user password to 'postgres'
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"

# Create user 'odoo' with password 'odoo'
sudo -u postgres psql -c "CREATE USER odoo WITH PASSWORD 'odoo';"

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/;s/^listen_addresses = 'localhost'/listen_addresses = '*'/;" /etc/postgresql/16/main/postgresql.conf

# Allow remote connections in pg_hba.conf
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
echo "host    all             all             ::/0                    md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

echo "PostgreSQL 16 installed, 'postgres' and 'odoo' users configured, and remote access enabled."