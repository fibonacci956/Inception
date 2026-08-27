#!/bin/sh
set -e

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

DB_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
DB_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld "$DATADIR"

# --- Idempotence : ne provisionner qu'au tout premier lancement ---
if [ ! -d "${DATADIR}/mysql" ]; then
    echo "[entrypoint] No existing database found, initializing datadir..."

    mysql_install_db \
        --datadir="$DATADIR" \
        --user=mysql \
        --skip-test-db >/dev/null

    echo "[entrypoint] Starting temporary local-only mysqld for provisioning..."
    mysqld \
        --datadir="$DATADIR" \
        --socket="$SOCKET" \
        --skip-networking \
        --user=mysql &
    TMP_PID=$!

    # --- Attente que le socket local réponde ---
    i=0
    until mysqladmin --socket="$SOCKET" ping >/dev/null 2>&1; do
        i=$((i + 1))
        if [ "$i" -ge 30 ]; then
            echo "[entrypoint] Error: temporary mysqld did not start in time." >&2
            exit 1
        fi
        sleep 1
    done

    echo "[entrypoint] Provisioning database, technical user and root password..."
    mysql --socket="$SOCKET" -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

        DELETE FROM mysql.user WHERE User='';

        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

        FLUSH PRIVILEGES;
EOSQL

    echo "[entrypoint] Stopping temporary mysqld..."
    mysqladmin --socket="$SOCKET" -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "$TMP_PID" 2>/dev/null || true

    echo "[entrypoint] Provisioning done."
else
    echo "[entrypoint] Existing database found in volume, skipping provisioning."
fi

echo "[entrypoint] Starting MariaDB in foreground (PID 1)..."
exec mysqld \
    --datadir="$DATADIR" \
    --socket="$SOCKET" \
    --pid-file=/run/mysqld/mysqld.pid \
    --user=mysql
