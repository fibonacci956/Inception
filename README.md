*This project has been created as part of the 42 curriculum by **hseffih**.*

## Description

**Inception** is a system administration project from the 42 school curriculum designed to deepen the understanding of containerization through Docker.

The goal is to design, configure, and deploy a complete, isolated, and secure web infrastructure composed of several interconnected containerized services:

* **NGINX**
* **WordPress + PHP-FPM**
* **MariaDB**

The entire architecture relies on custom-built images based on **Alpine Linux `3.23.5`**, without using pre-built services or the `latest` tag.

Incoming traffic is strictly filtered through a single **NGINX** reverse proxy, exposed on port `443` over **HTTPS**, using only secure protocols:

* `TLSv1.2`
* `TLSv1.3`

---

# Instructions

## Prerequisites

Before running the project, you will need:

- **Docker**
  - [Install Docker on Linux](https://docs.docker.com/engine/install/)
  - [Install Docker Desktop on Windows](https://docs.docker.com/desktop/setup/install/windows-install/)

- **Docker Compose V2**
  - Docker Compose V2 is included with Docker Desktop on Windows.
  - On Linux, you can follow the [official Docker Compose documentation](https://docs.docker.com/compose/install/).

- **sudo access on Linux**, required to manage the host directories used by the volumes.
  - [sudo documentation](https://www.sudo.ws/docs/)

### Windows Compatibility

The project can be run on:

- **Linux**, with Docker, Docker Compose V2, and `sudo` installed.
- **Windows**, provided that **Docker Desktop with the Linux engine and WSL2** is enabled.
  - [WSL2 documentation](https://learn.microsoft.com/windows/wsl/install)
  - [Docker Desktop with WSL2 documentation](https://docs.docker.com/desktop/features/wsl/)

> **Note:** A Linux virtual machine (VirtualBox, UTM, etc.) is not required if Docker Desktop with WSL2 is properly configured on Windows.

## Installation and Quick Start

### 1. Clone the Repository

Clone the repository and move into its root directory:

```bash
git clone <repository-url>
cd inception
```

### 2. Configure Environment Variables

Copy the example file:

```bash
cp srcs/.env.example srcs/.env
```

Then edit the `.env` file and provide, in particular:

* your `LOGIN`
* your `DOMAIN_NAME`

For example:

```env
LOGIN=hseffih
DOMAIN_NAME=hseffih.42.fr
```

### 3. Start the Infrastructure

Use the `Makefile` to build and start the entire infrastructure.

This command also prepares the volumes and automatically generates the required secrets:

```bash
make
```

### 4. Configure the Local Domain

Add the domain alias to the host machine's `/etc/hosts` file:

```plaintext
127.0.0.1 hseffih.42.fr
```

### 5. Access the Website

Open your browser and navigate to:

```text
https://hseffih.42.fr
```

---

# Resources & AI Usage

## Documentation & Standard References

The following resources were used for the design and implementation of the project:

- [Alpine Linux Documentation](https://docs.alpinelinux.org/)
- [Docker Documentation & Compose Specification](https://docs.docker.com/reference/compose-file/)
- [NGINX Admin Guide](https://docs.nginx.com/nginx/admin-guide/)
- [MariaDB Knowledge Base](https://mariadb.com/docs/)
- [WP-CLI Official Documentation](https://make.wordpress.org/cli/handbook/)

## Additional Guides & Resources

- [Inception 42 — A Comprehensive Guide to Dockerizing Your First Infrastructure](https://devabdilah.medium.com/inception-42-a-comprehensive-guide-to-dockerizing-your-first-infrastructure-part-iii-a10e93e9d922)
- [Inception 42 — Guide](https://inception.cluzet.fr/)

## Description of AI Usage by Task

As part of this project, artificial intelligence was used as a **technical assistant** to optimize certain development phases, in accordance with the educational guidelines.

Its use mainly focused on:

* reducing repetitive tasks;
* exploring architectural choices;
* analyzing technical behavior;
* reviewing and structuring code;
* writing documentation.

### Research and Design of Networking & Internal DNS

AI was used to analyze the behavior of different Docker network drivers:

* `bridge`
* `host`
* `none`

It was also used to explore and validate the operation of Docker's internal DNS server, accessible from containers via:

```text
127.0.0.11
```

### TLS Security & Cipher Suite Analysis

AI was used to study different TLS versions and compare modern protocols with outdated or vulnerable ones.

This notably helped document:

* the use of `TLSv1.2` and `TLSv1.3`;
* the deprecation of obsolete SSL protocols;
* historical vulnerabilities such as **POODLE**;
* TLS configuration hardening;
* the configuration of `ssl_ciphers`;
* disabling session tickets when relevant.

### Automation and Robustness of Entrypoint Scripts

AI was used to structure service initialization logic in order to ensure robust and idempotent execution.

This notably concerns:

* **MariaDB**
  * initialization with `mysql_install_db`;
  * temporary server startup;
  * automated creation of the database and users.

* **WordPress**
  * use of `wp-cli`;
  * connection retry management;
  * service availability checks;
  * prevention of unnecessary reinstallations.

### Writing and Structuring Documentation

AI was also used to improve the structure and formatting of the project's technical documentation:

* `README.md`
* `DEV_DOC.md`
* `USER_DOC.md`

It notably helped formalize the architectural comparisons required as part of the project.

---

# Project Description & Architectural Choices

The infrastructure is based on a `docker-compose.yml` file that centralizes the three main services:

* **NGINX**
* **WordPress**
* **MariaDB**

These services communicate through a custom bridge network named:

```text
inception_network
```

This architecture provides:

* service isolation;
* internal communication between containers;
* dynamic resolution of service names;
* limited network exposure;
* data persistence.

---

# Required Comparisons

## 1. Virtual Machines vs Docker

### Virtual Machine

A virtual machine virtualizes an entire physical machine.

It generally includes:

* virtualized or emulated hardware;
* a complete operating system;
* its own kernel;
* an independent system stack;
* a hypervisor allowing it to run.

Each VM therefore has its own complete environment, which results in:

* higher RAM consumption;
* higher CPU usage;
* greater disk space requirements;
* generally longer startup times.

### Docker

Docker relies on operating-system-level virtualization.

Containers notably use:

* **namespaces** for isolation;
* **cgroups** for resource management.

Unlike virtual machines, containers share the host system's kernel.

This allows for:

* fast startup;
* reduced resource consumption;
* higher service density;
* isolation suitable for applications and services.

### Choice in the Project

The project combines both approaches:

1. A **virtual machine** hosts the overall environment, in accordance with the educational requirements of the 42 curriculum.
2. Inside this virtual machine, **Docker** isolates each service:

```text
VM
└── Docker
    ├── NGINX
    ├── WordPress + PHP-FPM
    └── MariaDB
```

This approach makes it possible to benefit from both:

* the global isolation provided by the VM;
* the lightweight and modular nature of Docker containers.

---

## 2. Secrets vs Environment Variables

### Environment Variables

Environment variables are mainly used to provide configuration information to applications.

They are suitable for non-sensitive data, such as:

* the domain name;
* the database name;
* usernames;
* general configuration settings.

Examples:

```env
DOMAIN_NAME=hseffih.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

Environment variables should not be used to store sensitive secrets when they may be exposed through:

* configuration files;
* container inspection;
* processes;
* configuration or logging errors.

### Docker Secrets

Secrets allow sensitive information to be provided to services without placing it directly in environment variables or images.

Secrets are accessible inside containers as files, for example:

```text
/run/secrets/
```

They may contain:

* passwords;
* sensitive credentials;
* private keys;
* other confidential data.

### Choice in the Project

The project uses two separate mechanisms.

#### Public Configuration

The `.env` file contains non-sensitive information:

```env
DOMAIN_NAME=hseffih.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

#### Sensitive Information

Passwords are stored in secret files:

```text
secrets/
├── db_root_password.txt
├── db_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

These secrets are then mounted inside the containers under:

```text
/run/secrets/
```

This separation clearly distinguishes between:

* **configuration**;
* **sensitive data**.

---

## 3. Docker Network: Custom Bridge vs Host Network

### Host Network

With the network mode:

```text
--network host
```

the container directly uses the host machine's network stack.

The consequences notably include:

* no network isolation between the container and the host;
* direct use of the host's network interfaces;
* no need for port mapping in some cases.

However, this approach significantly reduces isolation and is not suitable for the architecture required for this project.

### Custom Bridge Network

A custom bridge network creates a private virtual network that allows containers to communicate with each other.

Services benefit from:

* internal IP addresses;
* network isolation;
* internal DNS resolution;
* the ability to communicate using service names.

For example:

```text
wordpress
mariadb
nginx
```

### Choice in the Project

The project exclusively uses a custom bridge network:

```yaml
networks:
  inception_network:
    driver: bridge
```

The network architecture can be represented as follows:

```text
Internet / Browser
        │
        │ HTTPS :443
        ▼
      NGINX
        │
        ├──────────► WordPress + PHP-FPM
        │
        └──────────► MariaDB
```

Only **NGINX** exposes port:

```text
443
```

to the host machine.

The **WordPress** and **MariaDB** services are not directly accessible from outside.

They communicate only through the internal Docker network.

---

## 4. Docker Volumes vs Bind Mounts

### Bind Mounts

A bind mount directly links a directory on the host machine to a path inside the container.

Conceptual example:

```text
Host machine
/home/user/data
        │
        ▼
Container
/var/lib/mysql
```

This approach directly depends on:

* the host system's structure;
* the paths being used;
* file system permissions.

It can also make the environment less portable and lead to permission issues.

### Docker Volumes

Docker volumes make it possible to manage data persistence independently from the lifecycle of containers.

They notably allow:

* data to be preserved after a container is removed;
* data to be separated from the image;
* persistent storage to be managed more easily.

In this project, the volumes are configured to meet the requirement that data be stored under:

```text
/home/<login>/data/
```

The Docker volume is associated with a specific host path through mount options.

### Choice in the Project

Two main volumes are used:

```text
/home/hseffih/data/
├── mariadb/
└── wordpress/
```

They ensure the persistence of data for:

* **MariaDB**
* **WordPress**

Configuration example:

```yaml
volumes:
  mariadb:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/hseffih/data/mariadb

  wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/hseffih/data/wordpress
```

This configuration makes it possible to:

* use volumes declared in Docker Compose;
* keep the data on the host machine;
* comply with the path required by the project subject;
* ensure data persistence even after the containers are recreated.

---

# Overall Architecture

The final architecture can be summarized as follows:

```text
                        ┌─────────────────────┐
                        │       Browser       │
                        └──────────┬──────────┘
                                   │
                               HTTPS :443
                                   │
                                   ▼
                        ┌─────────────────────┐
                        │       NGINX         │
                        │ Reverse Proxy + TLS │
                        └──────────┬──────────┘
                                   │
                     inception_network
                                   │
                                   ▼
                        ┌─────────────────────┐
                        │     WordPress       │
                        │      PHP-FPM        │
                        └──────────┬──────────┘
                                   │
                                   ▼
                        ┌─────────────────────┐
                        │      MariaDB        │
                        └─────────────────────┘
                                   │
                           Persistent Volumes
                                   │
                                   ▼
                      /home/hseffih/data/
                      ├── wordpress/
                      └── mariadb/
```

---

# Security

The main security mechanisms implemented are:

* Exclusive use of **HTTPS**.
* Exposure of port `443` only.
* Use of `TLSv1.2` and `TLSv1.3`.
* Disabling obsolete SSL protocols.
* Service isolation through a custom Docker bridge network.
* No direct exposure of WordPress and MariaDB.
* Separation between configuration variables and sensitive data.
* Use of secrets for passwords.
* Locally built images based on Alpine Linux.
* No use of the `latest` tag.
* Data persistence through Docker volumes.

---

## Author

**hseffih**

Project completed as part of the **42** curriculum.
