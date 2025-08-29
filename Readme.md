# SCRIPT AUTOMATION REPOSITORY

Scripts to automate software installations on linux servers.

## Install Caddy

- Download caddy installer script from github

```bash
    wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/caddy-ubuntu-installer.sh
```

- Execute caddy script with sudo permisions with params

  - <$CADDY_REVERSE_URL> - Ex: dominio.com
  - <$CADDY_REVERSE_PORT> - Ex: 8069

```bash
    sudo sh caddy-ubuntu-installer.sh <$CADDY_REVERSE_URL> <$CADDY_REVERSE_PORT>
```

## Install Postgres

- Download postgres installer script from github

```bash
    wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/postgres-ubuntu-installer.sh
```

- Execute postgres script with sudo permisions with params

  - <$PG_VERSION> - Ex: 16
  - <$PG_PASSWORD> - Ex: StrongPassword

```bash
    sudo sh postgres-ubuntu-installer.sh <$PG_VERSION> <$PG_PASSWORD>
```

## Install Only Odoo 18.0

- Download odoo installer script from github

```bash
    wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/odoo-ubuntu-installer.sh
```

- Execute odoo script with sudo permisions with params

  - <$ODOO_INSTALL_NAME> - Ex: nomecliente
  - <$ODOO_USER> - Ex: odoo
  - <$ODOO_DB_NAME> - Ex: mydatabase
  - <$ODOO_DB_PASSWORD> - Ex: StrongPassword
  - <$ODOO_PORT> - Ex: 8069

```bash
    sudo sh odoo-ubuntu-installer.sh <$ODOO_INSTALL_NAME> <$ODOO_USER> <$ODOO_DB_NAME> <$ODOO_DB_PASSWORD> <$ODOO_PORT> 
```

## Install Odoo 18.0 with postgres and caddy reverse proxy

- Download installer script from github

```bash
    wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/odoo-installer.sh
```

- Execute odoo script with sudo permisions with params

  - <$ODOO_USER> - Ex: odoo
  - <$ODOO_DB_NAME> - Ex: mydatabase
  - <$ODOO_DB_PASSWORD> - Ex: StrongPassword
  - <$ODOO_PORT> - Ex: 8069
  - <$PG_ADMIN_PASSWORD> - Ex. StrongPassword2
  - <$ODOO_URL> - Ex. domonio.com

```bash
    sudo sh odoo-installer.sh <$ODOO_USER> <$ODOO_DB_NAME> <$ODOO_DB_PASSWORD> <$ODOO_PORT> <$PG_VERSION> <$PG_ADMIN_PASSWORD> <$ODOO_URL>
```

## postgres-migrate-database.ps1

- Scaricare script di migrazione databases tra due istanze postgres

```bash
    wget https://raw.githubusercontent.com/orionedp/quick-automation/postgres-migrate-database.ps1
```

- Eseguire lo script con parametri

  - <$oldversion> - Ex: 12
  - <$newversion> - Ex: 16
  - <$server> - Ex: localhost
  - <$username> - Ex: postgres
  - <$oldport> - Ex: 5432
  - <$newport> - Ex: 5434

```bash
    ./postgres-migrate-database.ps1 <$oldversion> <$newversion> <$server> <$username> <$oldport> <$newport>
```
