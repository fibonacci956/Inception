#!/bin/sh
set -e   # Stoppe le script immédiatement si une commande échoue

# Wrapper wp-cli avec une limite mémoire de 512M (128M par défaut casse souvent)
wp() 
{
    timeout 120 php -d memory_limit=512M /usr/local/bin/wp "$@"
}

DB_HOST="mariadb"
DB_PORT="3306"
WP_PATH="/var/www/html"

# --- 1. Attente de MariaDB ---
MAX_TRIES=60
i=0
ready=0

echo "Waiting for MariaDB on ${DB_HOST}:${DB_PORT}..."

while [ "$i" -lt "$MAX_TRIES" ]; do
    # Ce test vérifie non seulement que le port répond, mais aussi que
    # le serveur accepte l'authentification ET peut exécuter une vraie
    # requête SQL
    DB_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
    if mariadb -h "$DB_HOST" -u"$MYSQL_USER" -p"$DB_PASSWORD" \
           -e "SELECT 1" >/dev/null 2>&1; then
        ready=1
        break
    fi

    i=$((i + 1))
    echo "MariaDB not ready yet, retrying... (${i}/${MAX_TRIES})"
    sleep 1
done

if [ "$ready" -eq 0 ]; then
    echo "Error: MariaDB not reachable after ${MAX_TRIES}s, aborting." >&2
    exit 1
fi

echo "MariaDB is ready."

# --- 2. Lecture des secrets (fichiers -> variables shell) ---
DB_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
WP_ADMIN_PASSWORD=$(cat "$WP_ADMIN_PASSWORD_FILE")
WP_USER_PASSWORD=$(cat "$WP_USER_PASSWORD_FILE")

cd "$WP_PATH"

# --- Fonction: crée le 2e utilisateur seulement s'il n'existe pas encore ---
create_wp_user_if_missing()
{
    if ! wp user list --field=user_login --path="$WP_PATH" --allow-root | grep -qx "$WP_USER"; then
        wp user create "$WP_USER" "$WP_USER_EMAIL" \
            --path="$WP_PATH" \
            --user_pass="$WP_USER_PASSWORD" \
            --role=author \
            --allow-root
        echo "User $WP_USER created."
    else
        echo "User $WP_USER already exists, skipping."
    fi
}

# --- Fonction: installe WordPress (core install) + crée le 2e user ---
# Factorisée pour être appelée depuis les deux branches (1er lancement / rattrapage)
install_wp()
{
    wp core install \
        --path="$WP_PATH" \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root   # installe WordPress + crée l'admin
 
    create_wp_user_if_missing   # crée (ou rattrape) le 2e utilisateur non-admin
}

# --- 3. Installation (uniquement si pas déjà fait) ---
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Did not find wp-config.php, Installing for the first time..."

    wp core download --path="$WP_PATH" --allow-root --force   # télécharge le core WordPress

    wp config create \
        --path="$WP_PATH" \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$DB_HOST" \
        --allow-root   # génère wp-config.php avec les infos DB

    install_wp
    echo "WordPress installed with success."

else
    echo "wp-config.php already installed."
    if ! wp core is-installed --path="$WP_PATH" --allow-root; then
        echo "WordPress not installed but configured, starting installation again..."
        install_wp
    else
        echo "WordPress already installed, skipping"
        create_wp_user_if_missing   # sécurité: rattrape le 2e user s'il manquait
    fi
fi

# --- 5. passer lowner a l'utilisateur wordpress, nobody est tres generique
chown -R wordpress:wordpress /var/www/html

# --- 4. Démarrage du process principal (PID 1 = php-fpm) ---
exec php-fpm83 -F
