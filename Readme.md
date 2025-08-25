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
