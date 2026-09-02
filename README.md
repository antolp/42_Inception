*This project has been created as part of the 42 curriculum by anle-pag.*

# Inception

## Description

Inception is a system administration project that deploys a small web infrastructure with Docker Compose inside a virtual machine.

The stack contains three services built from three Dockerfiles:

- **NGINX**: HTTPS entrypoint on port 443 using TLS 1.2/1.3
- **WordPress + PHP-FPM**: serves WordPress internally on port 9000
- **MariaDB**: stores the WordPress database internally on port 3306

The containers communicate through a Docker bridge network. Two Docker named volumes persist the MariaDB data and WordPress files. Non-secret configuration is stored in `srcs/.env`,  passwords are provided through Docker Compose secrets.

The service sources are under `srcs/requirements/`, with one Dockerfile plus configuration/startup files per service.

### Main design choices

- **Virtual Machines vs Docker**: a VM runs its own kernel and virtual hardware; containers share the host kernel and isolate processes, they are way lighter. (Inception itself still runs inside a VM as required by the subject).
- **Secrets vs Environment Variables**: Environment variables store non-sensitive configuration. Passwords are kept in local secret files and mounted as Docker secrets.
- **Docker Network vs Host Network**: the services use a dedicated bridge network and Docker DNS. Host networking is not used between services, only NGINX publishes port 443.
- **Docker Volumes vs Bind Mounts**: named volumes are persistent storage managed by Docker. Bind mounts directly map a chosen host path. This project requires named volumes, Docker's data root is configured under `/home/anle-pag/data/`.

## Instructions

Prerequisites:

- UNIX-like OS
- Docker Engine and Docker Compose
- required local files in `secrets/`
- `login.42.fr` resolving to the VM IP (/etc/hosts map, or use localhost:443)

Build and start from the repository root:

```sh
make
```

Useful commands:

```sh
make build
make up
make down
make stop
make start
make logs
make ps
make re
```

Website: `https://<login>.42.fr` 

WordPress administration: `https://<login>.42.fr/wp-admin`

The certificate is self-signed, so a browser warning is expected.

## Resources

- Docker Compose documentation: https://docs.docker.com/compose/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/docs/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI documentation: https://wp-cli.org/
- cool article on inception (in french) : https://app.notion.com/p/INCEPTION-2b50e43c57ea8038a822d04f791675f9

### Use of AI

AI was used as a learning and review tool to explain Docker concepts, compare implementation approaches, diagnose runtime errors from logs (lots of that) and propose tests. AI suggestions were thoroughly reviewed, tested on the VM, and corrected when necessary before being kept in the project.
