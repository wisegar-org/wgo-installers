#!/bin/bash
set -e
PG_VERSION="16"
PG_PASSWORD=$1
PG_USER=$2
PG_USER_PASSWORD=$3
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <postgres_password> <custom_user> <custom_user_password>"
    exit 1
fi
echo "PG_VERSION: $PG_VERSION"
echo "PG_PASSWORD: $1"
echo "PG_USER: $2"
echo "PG_USER_PASSWORD: $3"

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

# Create custom user with password
sudo -u postgres psql -c "CREATE USER $PG_USER WITH PASSWORD '$PG_USER_PASSWORD';"

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/;s/^listen_addresses = 'localhost'/listen_addresses = '*'/;" /etc/postgresql/16/main/postgresql.conf

# Allow remote connections in pg_hba.conf
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
echo "host    all             all             ::/0                    md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

echo "PostgreSQL $PG_VERSION installed, 'postgres' and '$PG_USER' users configured, and remote access enabled."