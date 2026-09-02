# Inception — User Documentation

## Services

The stack provides:

- **NGINX**: HTTPS access on port 443.
- **WordPress + PHP-FPM**: website and administration panel.
- **MariaDB**: persistent WordPress database.

Only NGINX is exposed to the host.

## Start and stop

Run commands from the repository root.

```sh
make          # build and start
make down     # remove containers/network, keep volumes
make stop     # stop existing containers
make start    # restart stopped containers
make ps       # show service status
make logs     # follow logs
```

## Access

Website:

```text
https://anle-pag.42.fr
```

Administration panel:

```text
https://anle-pag.42.fr/wp-admin
```

The TLS certificate is self-signed, so a browser warning is expected. HTTP on port 80 is intentionally unavailable.

## Credentials

Non-sensitive settings are stored in:

```text
srcs/.env
```

Passwords are stored locally in:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

These files are ignored by Git and must exist before the first startup.

Changing a secret after initialization does not automatically update passwords already stored in MariaDB or WordPress; persistent credentials must also be updated, or the volumes reinitialized if their data can be discarded.

## Basic checks

```sh
make ps
curl -k https://anle-pag.42.fr
docker volume ls
docker network ls
```

For service logs:

```sh
make logs
```
