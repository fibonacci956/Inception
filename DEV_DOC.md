# Developer Documentation (`DEV_DOC.md`) — Inception Project

This document describes the technical architecture, environment setup, container lifecycle, logging, monitoring, and data management for developers working on the **Inception** project.

---

# 1. Setting Up the Environment from Scratch

## 1.1 System Prerequisites

The project requires:

- A Linux machine (**Debian/Ubuntu recommended**).
- A configured local user.
- **Docker Engine**.
- **Docker Compose V2**.
- `make`.
- `openssl`.
- `curl`.

The project dynamically uses the value of `LOGIN` defined in `srcs/.env`.

For example, if:

```env
LOGIN=hseffih
```

the persistent data directory will be:

```text
/home/hseffih/data
```

The Makefile computes this path using:

```makefile
LOGIN		:= $(shell grep -E '^LOGIN=' srcs/.env 2>/dev/null | cut -d '=' -f2)
DATA_DIR	:= /home/$(LOGIN)/data
```

---

## 1.2 Environment File

Before starting the project, create the environment file:

```bash
cp srcs/.env.example srcs/.env
```

Then edit it according to your environment.

The file must contain a valid `LOGIN` variable.

Example:

```env
LOGIN=hseffih
```

The Makefile uses this value to determine:

- The host data directory.
- The project domain.

The domain is generated as:

```makefile
DOMAIN := $(LOGIN).42.fr
```

For example, `LOGIN=hseffih` produces:

```text
hseffih.42.fr
```

### Environment Validation

Before creating the persistence directories, the Makefile executes:

```bash
make check-env
```

This target verifies that `LOGIN` is correctly defined.

If `srcs/.env` does not exist or `LOGIN` is missing, the process stops with an error. This prevents invalid paths such as:

```text
/home//data
```

---

# 2. Secret Management

Sensitive passwords must not be stored directly in the source code or in the `.env` file.

The Makefile automatically creates missing secret files in the `secrets/` directory:

```text
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

The corresponding Makefile configuration is:

```makefile
SECRETS_DIR	:= secrets
SECRET_FILES	:= db_password db_root_password wp_admin_password wp_user_password
```

Secrets are generated using:

```bash
openssl rand -base64 16
```

## 2.1 Idempotent Secret Generation

The `make secrets` command only generates a secret if its file does not already exist or is empty.

Therefore, running:

```bash
make secrets
```

multiple times does not overwrite existing passwords.

This is particularly important for MariaDB because changing an existing password while keeping an already initialized database could cause authentication problems.

---

# 3. Preparing Persistent Directories

Before starting the containers, the project creates the directories used by the persistent volumes.

Run:

```bash
make prepare
```

This command first checks the environment and then creates:

```text
/home/<LOGIN>/data/
├── mariadb/
└── wordpress/
```

For example, with:

```env
LOGIN=hseffih
```

the directories are:

```text
/home/hseffih/data/
├── mariadb/
└── wordpress/
```

The directories are created using:

```bash
mkdir -p $(DATA_DIR)/mariadb
mkdir -p $(DATA_DIR)/wordpress
```

Creating these directories before Docker starts is important because the project uses Docker named volumes configured with host bind mounts. If the directories do not exist, Docker may create them automatically with permissions that are not suitable for the containers.

---

# 4. Building and Starting the Project

The project is managed from the root of the repository through the `Makefile`.

The main Docker Compose command is defined as:

```makefile
COMPOSE := docker compose -f srcs/docker-compose.yml
```

All Compose commands therefore use:

```bash
docker compose -f srcs/docker-compose.yml
```

## 4.1 Main Command

To build and start the entire project:

```bash
make
```

or:

```bash
make all
```

The workflow is:

```text
Environment validation
        │
        ▼
Creation of data directories
        │
        ▼
Generation of missing secrets
        │
        ▼
Docker image build
        │
        ▼
Container startup
```

---

# 5. Main Makefile Commands

| Command | Description |
|---|---|
| `make` or `make all` | Validates the environment, creates persistence directories, generates missing secrets, builds the images, and starts the services. |
| `make build` | Prepares the environment and secrets, then builds the Docker images. |
| `make up` | Prepares the environment and secrets, then starts the services in detached mode. |
| `make down` | Stops and removes the containers and Compose-managed network. |
| `make stop` | Stops the containers without removing them. |
| `make start` | Starts previously created containers. |
| `make restart` | Executes `make down` followed by `make up`. |
| `make clean` | Stops the project and removes the Docker named volumes using `docker compose down -v`. |
| `make fclean` | Performs `clean` and removes the project images using `docker compose down --rmi all -v`. |
| `make deepclean` | Performs `fclean`, then interactively deletes the persistent data stored in `/home/<LOGIN>/data/`. |
| `make re` | Executes `make fclean` followed by `make all`. |
| `make check-env` | Verifies that `srcs/.env` exists and that `LOGIN` is defined. |
| `make prepare` | Creates the MariaDB and WordPress persistence directories. |
| `make secrets` | Generates missing secret files without overwriting existing ones. |

---

# 6. Container Monitoring

## 6.1 Basic Status

To display the status of the project services:

```bash
make ps
```

This executes:

```bash
docker compose -f srcs/docker-compose.yml ps
```

## 6.2 Full Monitoring

For more detailed information:

```bash
make ps-full
```

This displays:

- The state of the project containers.
- Healthcheck status.
- Restart count.
- CPU and memory usage.
- Containers connected to the Docker network.
- Project volumes.
- Docker images related to MariaDB, WordPress, and NGINX.

Example sections displayed by the command:

```text
=== ÉTAT DES CONTENEURS ===

=== HEALTHCHECKS ===

=== RESSOURCES (CPU/MEM live) ===

=== RÉSEAUX ===

=== VOLUMES ===

=== IMAGES DU PROJET ===
```

---

# 7. Viewing Container Logs

The Makefile provides shortcuts for viewing Docker Compose logs.

## 7.1 Logs from All Services

To follow logs from all services:

```bash
make logs
```

This executes:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

The `-f` option continuously displays new log entries. Stop log monitoring with:

```text
Ctrl + C
```

## 7.2 NGINX Logs

To follow the NGINX logs:

```bash
make logs-nginx
```

Equivalent Docker Compose command:

```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
```

This is useful for debugging HTTPS connections, TLS certificates, reverse proxy behavior, and HTTP errors.

## 7.3 WordPress Logs

To follow the WordPress container logs:

```bash
make logs-wordpress
```

Equivalent Docker Compose command:

```bash
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

This can be useful for debugging WordPress startup, PHP-FPM issues, database connection problems, and WordPress initialization.

## 7.4 MariaDB Logs

To follow the MariaDB logs:

```bash
make logs-mariadb
```

Equivalent Docker Compose command:

```bash
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

This can be useful for debugging database initialization, authentication problems, and MariaDB startup failures.

---

# 8. Checking the Complete Project State

The Makefile provides a `check` target for a global inspection of the Docker environment and the website.

Run:

```bash
make check
```

The command displays:

```text
=== VOLUMES ===

=== NETWORKS ===

=== CONTAINERS ===

=== SITE (<LOGIN>.42.fr) ===
```

It then attempts an HTTPS request:

```bash
curl -Ik https://<LOGIN>.42.fr
```

If the website cannot be reached, the command displays:

```text
Site injoignable
```

---

# 9. Interactive Access to Containers

To open a shell inside a running container, first identify its name:

```bash
docker ps
```

Then run:

```bash
docker exec -it <container_name> sh
```

For example:

```bash
docker exec -it srcs-wordpress-1 sh
```

> Container names may vary depending on the Docker Compose project name and configuration.

Using Docker Compose is often more convenient:

```bash
docker compose -f srcs/docker-compose.yml exec wordpress sh
```

Similarly:

```bash
docker compose -f srcs/docker-compose.yml exec nginx sh
```

or:

```bash
docker compose -f srcs/docker-compose.yml exec mariadb sh
```

---

# 10. Docker Network

The project services communicate through an internal Docker network.

The `make ps-full` command attempts to inspect:

```text
inception_network
```

To inspect the network directly:

```bash
docker network inspect inception_network
```

Depending on the Docker Compose configuration, the exact network name may vary.

Network inspection provides information about:

- Connected containers.
- Internal IP addresses.
- Docker network configuration.

---

# 11. Data Location and Persistence

Stateful service data is stored outside the containers, directly on the host machine.

The base directory is dynamically generated from `LOGIN`:

```text
/home/<LOGIN>/data
```

For example:

```env
LOGIN=hseffih
```

produces:

```text
/home/hseffih/data/
├── mariadb/
└── wordpress/
```

## 11.1 MariaDB Data

MariaDB persistent data is stored in:

```text
/home/<LOGIN>/data/mariadb
```

## 11.2 WordPress Data

WordPress persistent data is stored in:

```text
/home/<LOGIN>/data/wordpress
```

---

# 12. Docker Volume Persistence Mechanism

The project uses Docker named volumes configured with the `local` driver and bind mount options.

The configuration follows this pattern:

```yaml
driver: local
driver_opts:
  type: none
  o: bind
  device: /home/<LOGIN>/data/...
```

The volumes connect Docker-managed volumes to physical directories on the host.

Typical volumes are:

```text
mariadb_volume
wordpress_volume
```

The persistence architecture can be represented as:

```text
MariaDB Container
        │
        ▼
MariaDB Docker Volume
        │
        ▼
/home/<LOGIN>/data/mariadb


WordPress Container
        │
        ▼
WordPress Docker Volume
        │
        ▼
/home/<LOGIN>/data/wordpress
```

---

# 13. Data Persistence and Cleanup

Because the persistent data is stored on the host:

- Containers can be removed and recreated.
- Docker images can be rebuilt.
- Persistent data can survive container recreation.
- Data remains available as long as the corresponding host directories are not deleted.

However, the cleanup commands have different effects.

## 13.1 `make down`

```bash
make down
```

This removes the Compose containers and associated Compose resources. The physical host directories remain untouched.

## 13.2 `make clean`

```bash
make clean
```

This executes:

```bash
docker compose -f srcs/docker-compose.yml down -v
```

The Docker named volumes are removed. The Makefile does not explicitly delete the contents of:

```text
/home/<LOGIN>/data/mariadb
```

or:

```text
/home/<LOGIN>/data/wordpress
```

## 13.3 `make fclean`

```bash
make fclean
```

This removes:

- Containers.
- Docker volumes.
- Project images.

The persistent host directories are not explicitly deleted.

## 13.4 `make deepclean`

```bash
make deepclean
```

This command:

1. Checks that `LOGIN` is defined.
2. Executes `make fclean`.
3. Requests confirmation.
4. Deletes the contents of the MariaDB and WordPress persistence directories.

The confirmation prompt is:

```text
Confirmer ? [y/N]
```

Only entering:

```text
y
```

confirms the deletion.

The command removes:

```text
/home/<LOGIN>/data/mariadb/*
```

and:

```text
/home/<LOGIN>/data/wordpress/*
```

This operation is irreversible.

> **Warning:** `make deepclean` permanently deletes the project's persistent data stored inside the MariaDB and WordPress data directories.

---

# 14. Simplified Project Lifecycle

The standard lifecycle is:

```text
make
 │
 ├── build
 │    │
 │    ├── prepare
 │    │    └── check-env
 │    │
 │    └── secrets
 │
 └── up
      │
      ├── prepare
      │    └── check-env
      │
      ├── secrets
      │
      └── Docker Compose up -d
              │
              ├── NGINX
              ├── WordPress
              └── MariaDB
```

The persistence architecture is:

```text
MariaDB Container
        │
        ▼
mariadb_volume
        │
        ▼
/home/<LOGIN>/data/mariadb


WordPress Container
        │
        ▼
wordpress_volume
        │
        ▼
/home/<LOGIN>/data/wordpress
```

---

# 15. Typical Development Workflow

## Start the project

```bash
make
```

## Check container status

```bash
make ps
```

For more detailed information:

```bash
make ps-full
```

## Follow all logs

```bash
make logs
```

## Follow NGINX logs

```bash
make logs-nginx
```

## Follow WordPress logs

```bash
make logs-wordpress
```

## Follow MariaDB logs

```bash
make logs-mariadb
```

## Check the website

```bash
make check
```

## Stop the project

```bash
make stop
```

## Restart the project

```bash
make restart
```

## Remove containers and Docker volumes

```bash
make clean
```

## Completely rebuild the Docker environment

```bash
make re
```

## Permanently remove persistent project data

```bash
make deepclean
```

Use `make deepclean` only when you intentionally want to completely reset MariaDB and WordPress data.

---

# 16. Summary

The project architecture is designed around the following principles:

- Docker Compose manages the application services.
- The `Makefile` provides a simple interface for building, starting, stopping, monitoring, logging, and cleaning the project.
- `LOGIN` dynamically determines the persistence directory and project domain.
- Secrets are generated automatically and are not overwritten once created.
- MariaDB and WordPress data are stored persistently on the host.
- Docker named volumes use bind mount configuration to connect containers to host directories.
- Dedicated Makefile commands simplify log monitoring for NGINX, WordPress, and MariaDB.
- `make deepclean` is the only Makefile command that explicitly deletes the persistent data stored on the host.

This architecture allows the Docker environment to be rebuilt while keeping persistent application data, unless an explicit deep cleanup is requested.
