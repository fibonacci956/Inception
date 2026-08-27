# Developer Documentation (`DEV_DOC.md`) — Inception Project

This document describes the technical architecture, environment setup, container lifecycle, and data management for developers working on the **Inception** project.

---

## 1. Setting Up the Environment from Scratch

### 1.1 System Prerequisites

* A Linux machine (**Debian/Ubuntu recommended**) with a configured user, for example `hseffih`.
* **Docker Engine** version `24.x` or later.
* **Docker Compose V2**.
* `make`.
* `openssl`.

### 1.2 Environment File

Copy the example file and adapt it to your environment:

```bash
cp srcs/.env.example srcs/.env
```

The `srcs/.env` file contains non-sensitive configuration variables, such as:

* The WordPress login.
* The domain name.
* Database names.
* Usernames.

> Sensitive information, such as passwords, must not be stored directly in the `.env` file.

### 1.3 Secret Management

Sensitive passwords must never be written in plain text in the source code or in the `.env` file.

The `Makefile` automatically generates any missing secret files in the `secrets/` directory.

The following files are concerned:

```text
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

---

## 2. Building and Starting the Project

The project is entirely managed through a `Makefile` located at the root of the repository.

It automates, among other things:

* Environment validation.
* Creation of the directories required for volumes.
* Generation of missing secrets.
* Building Docker images.
* Starting containers with Docker Compose.

### 2.1 Main Makefile Commands

| Command              | Description                                                                                                                                                                      |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `make` or `make all` | Checks the environment, creates the required directories, generates missing secrets, builds the images, and starts the containers in the background.                            |
| `make down`          | Stops and removes the containers as well as the associated network.                                                                                                              |
| `make stop`          | Stops the containers without removing them.                                                                                                                                      |
| `make start`         | Restarts existing containers without recreating them.                                                                                                                             |
| `make restart`       | Performs a complete stop and restart cycle for the services.                                                                                                                      |
| `make clean`         | Stops the containers and removes the Docker named volumes associated with the project.                                                                                            |
| `make fclean`        | Performs a thorough cleanup: stops the services, removes the volumes, and removes the project images.                                                                             |
| `make deepclean`     | Performs a critical and interactive cleanup: removes the project's containers and images, then physically deletes the contents of `/home/hseffih/data/` after confirmation. |
| `make re`            | Runs `make fclean` followed by `make all` to completely rebuild the project.                                                                                                     |

---

## 3. Useful Commands for Managing Containers and Volumes

### 3.1 Checking Container Status

To display the status of the services:

```bash
make ps
```

For more detailed information:

```bash
make ps-full
```

These commands allow you to check the status of the containers and, depending on the configuration, the status of the **healthchecks**.

### 3.2 Viewing Logs

To follow the logs of a specific service:

```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
```

```bash
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

```bash
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

### 3.3 Interactive Access to a Container

To open a shell inside the WordPress container:

```bash
docker exec -it srcs-wordpress-1 sh
```

> The exact container name may vary depending on the Docker Compose configuration.

To check the names of currently running containers:

```bash
docker ps
```

### 3.4 Inspecting the Docker Network

To inspect the project's internal network:

```bash
docker network inspect inception_network
```

This command allows you to view, among other things:

* The containers connected to the network.
* Internal IP addresses.
* Network settings used by Docker.

---

## 4. Data Location and Persistence

To meet the persistence requirements of the **Inception** project, data from stateful services is stored outside the containers, directly on the host machine.

### 4.1 Data Location on the Host

The data is stored in the following directories:

```text
/home/hseffih/data/
├── mariadb/
│   └── MariaDB database data
│
└── wordpress/
    └── WordPress files, content, and uploads
```

More specifically:

| Service   | Location on the Host              |
| --------- | --------------------------------- |
| MariaDB   | `/home/hseffih/data/mariadb`      |
| WordPress | `/home/hseffih/data/wordpress`    |

### 4.2 Persistence Mechanism

The Docker named volumes:

* `mariadb_volume`
* `wordpress_volume`

use the `local` driver with a **bind mount** configuration.

The mechanism relies in particular on the following options:

```yaml
driver: local
driver_opts:
  type: none
  o: bind
  device: /home/hseffih/data/...
```

This configuration directly maps a Docker volume to a physical directory on the host machine.

### 4.3 Persistence Guarantees

Thanks to this architecture:

* Data is not stored exclusively inside the containers.
* Removing or recreating containers does not automatically cause the loss of data stored on the host.
* MariaDB and WordPress data remains accessible as long as the corresponding directories on the host are not deleted.

> **Warning:** the `make deepclean` command physically deletes the contents of the `/home/hseffih/data/` directory after confirmation. This operation therefore permanently removes the project's persistent data.

---

## 5. Simplified Project Lifecycle

The standard project lifecycle can be summarized as follows:

```text
make
  │
  ├── Environment validation
  │
  ├── Creation of data directories
  │
  ├── Generation of missing secrets
  │
  ├── Docker image build
  │
  └── Service startup
          │
          ├── NGINX
          ├── WordPress
          └── MariaDB
```

Persistent data remains stored on the host:

```text
MariaDB Container ──────► /home/hseffih/data/mariadb
WordPress Container ────► /home/hseffih/data/wordpress
```

This separation between containers and persistent data makes it possible to rebuild the application environment without losing data, as long as the persistence directories on the host are not deleted.
