# A FINIR AVANT DE PUSH
# Inception — Developer Documentation

## Prerequisites and VM setup

Required tools:

- Linux virtual machine
- Docker Engine
- Docker Compose
- GNU Make

`anle-pag.42.fr` must resolve to the VM IP address through the appropriate hosts file.

The project uses ordinary Docker named volumes. Configure Docker's data root under the subject-required path, for example in `/etc/docker/daemon.json`:

```json
{
  "data-root": "/home/anle-pag/data/docker"
}
```

Restart Docker and verify:

```sh
docker info | grep "Docker Root Dir"
```

## Configuration and secrets

Non-sensitive configuration is stored in `srcs/.env`.

Required local secret files:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Example creation:

```sh
openssl rand -hex 16 > secrets/db_password.txt
openssl rand -hex 16 > secrets/db_root_password.txt
openssl rand -hex 16 > secrets/wp_admin_password.txt
openssl rand -hex 16 > secrets/wp_user_password.txt
chmod 600 secrets/*.txt
```

## Build and launch

From the repository root:

```sh
make
```

Makefile targets:

```sh
make prepare
make build
make up
make down
make stop
make start
make logs
make ps
make re
```

The Makefile uses:

```text
docker compose --env-file srcs/.env -f srcs/docker-compose.yaml
```

Useful direct commands:

```sh
docker compose --env-file srcs/.env -f srcs/docker-compose.yaml config
docker compose --env-file srcs/.env -f srcs/docker-compose.yaml ps
docker compose --env-file srcs/.env -f srcs/docker-compose.yaml logs
docker compose --env-file srcs/.env -f srcs/docker-compose.yaml exec <service> sh
```

## Architecture

```text
Client --HTTPS:443--> NGINX --FastCGI:9000--> WordPress/PHP-FPM --MariaDB:3306--> MariaDB
```

All services share the `inception` bridge network. Docker DNS allows service names such as `wordpress` and `mariadb` to be used instead of fixed IP addresses.

## Persistent data

Two named volumes are used:

```text
mariadb_data   -> /var/lib/mysql
wordpress_data -> /var/www/html
```

`wordpress_data` is shared by WordPress and NGINX. Named volumes survive container recreation, so `make down` does not remove the website or database data.

Inspect them with:

```sh
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

To deliberately delete all project volumes:

```sh
docker compose --env-file srcs/.env -f srcs/docker-compose.yaml down --volumes
```

This is destructive.

## Service startup summary

- **MariaDB** initializes its data directory/database when required, then starts `mariadbd` as the main process.
- **WordPress** waits for MariaDB, configures WordPress with WP-CLI when required, then starts PHP-FPM in the foreground.
- **NGINX** generates its self-signed certificate/configuration, validates it with `nginx -t`, then starts NGINX in the foreground.
