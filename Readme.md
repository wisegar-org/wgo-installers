# SCRIPT AUTOMATION REPOSITORY

Scripts to automate software installations on linux servers.

## Install Caddy

- Download caddy installer script from github

```bash
    wget https://raw.githubusercontent.com/wisegar-org/wgo-installers/main/caddy-ubuntu-installer.sh
```

- Execute caddy script with sudo permisions with params

    <$CADDY_REVERSE_URL> - Ex: dominio.com
    <$CADDY_REVERSE_PORT> - Ex: 8069

```bash
    sudo sh caddy-ubuntu-installer.sh <$CADDY_REVERSE_URL> <$CADDY_REVERSE_PORT>
```
