# User Documentation (USER_DOC.md) — Inception Project

This guide explains, in simple terms, how to use, administer, and verify the proper functioning of the **Inception** infrastructure.

---

## 1. Services Provided by the Stack

The infrastructure consists of three interconnected containerized services:

### 1.1 NGINX — Reverse Proxy & TLS

NGINX acts as the application's single entry point on port `443`.

Its main responsibilities are:

* Encrypting and decrypting communications using **TLSv1.2** and **TLSv1.3**.
* Using a **self-signed** certificate.
* Forwarding PHP requests to the WordPress container through the internal Docker network.

### 1.2 WordPress + PHP-FPM

This service is the engine behind the website.

It is responsible for:

* Processing the PHP application through **PHP-FPM**.
* Managing the WordPress website files.
* Communicating with the MariaDB database.
* Automating the initial installation and configuration of WordPress using **WP-CLI**.
* Automatically creating the users required during the first startup.

### 1.3 MariaDB

MariaDB is the relational database management system used by WordPress.

It stores, among other things:

* Posts.
* Pages.
* Users.
* WordPress settings.

The database is isolated from the external network and can only be accessed by authorized services through the Docker network.

---

## 2. Starting and Stopping the Project

### Start the Project

To start the infrastructure in the background:

```bash
make
```

### Stop the Project Without Losing Data

```bash
make down
```

### Restart the Project

```bash
make restart
```

---

## 3. Accessing the Website and the Administration Panel

### Configure the Local Domain Name

Make sure the domain name points to your virtual machine by adding an entry to the `/etc/hosts` file on your client machine:

```text
<VM_IP_ADDRESS> hseffih.42.fr
```

For example:

```text
127.0.0.1 hseffih.42.fr
```

### Access the Public Website

Open your browser and go to:

```text
https://hseffih.42.fr
```

> **Note:** Since the TLS certificate is self-signed, your browser will probably display a security warning. You will need to accept the security exception to continue to the website.

### Access the WordPress Administration Panel

To access the WordPress administration panel, go to:

```text
https://hseffih.42.fr/wp-admin
```

---

## 4. Locating and Managing Credentials

For security reasons, passwords are never stored in plain text in the source code or in the Git repository.

### Where Can I Find the Passwords?

Files containing secrets are stored locally in the `secrets/` directory at the root of the project. This directory is ignored by Git.

The available files are:

* `secrets/db_password.txt`: password for the database user.
* `secrets/db_root_password.txt`: password for the MariaDB `root` user.
* `secrets/wp_admin_password.txt`: password for the WordPress administrator.
* `secrets/wp_user_password.txt`: password for the second WordPress user, who has the **Author** role.

### View a Password

For example, to display the WordPress administrator password:

```bash
cat secrets/wp_admin_password.txt
```

### Default Administrator Credentials

The configuration information is defined in `srcs/.env`.

* **Administrator username:** `hseffih`
* **Administrator email:** `hseffih@student.42.fr`

> The administrator username does not contain a forbidden term such as `admin`.

---

## 5. Verifying That the Services Are Working Correctly

### Quick Check

Use the following command:

```bash
make check
```

This command checks, among other things:

* The status of Docker volumes.
* The status of Docker networks.
* The active containers.
* Website accessibility using a `curl` test.

### Detailed Check

To display the detailed status of the services and their *healthchecks*:

```bash
make ps-full
```

This command allows you to verify that:

* Each container is in a **healthy** state.
* Services are not restarting unexpectedly.
* The restart count remains stable, ideally at `0`.
* Container resource usage can be monitored.

---

## 6. Summary of Useful Commands

| Action | Command |
| --- | --- |
| Start the project | `make` |
| Stop the services | `make down` |
| Restart the project | `make restart` |
| Quickly check the infrastructure | `make check` |
| Display detailed container status | `make ps-full` |

---

## 7. Important Points

* The website is accessible only through **HTTPS** on port `443`.
* The TLS certificate is **self-signed**, which may trigger a warning in the browser.
* MariaDB is not directly accessible from outside the infrastructure.
* Data is preserved in Docker volumes so that it survives container shutdowns or restarts.
* Passwords are stored in the `secrets/` directory and must not be added to the Git repository.
* WordPress is configured automatically during initialization using **WP-CLI**.
