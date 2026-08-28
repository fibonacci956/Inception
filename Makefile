# ============================================================
# Inception - Makefile
# ============================================================

LOGIN		:= $(shell grep -E '^LOGIN=' srcs/.env 2>/dev/null | cut -d '=' -f2)
DATA_DIR	:= /home/$(LOGIN)/data
COMPOSE		:= docker compose -f srcs/docker-compose.yml
SECRETS_DIR	:= secrets
SECRET_FILES	:= db_password db_root_password wp_admin_password wp_user_password

# ------------------------------------------------------------
# Cible principale
# ------------------------------------------------------------
all: build up

# ------------------------------------------------------------
# Garde de sécurité
# ------------------------------------------------------------

# Vérifie que srcs/.env existe et que LOGIN y est bien défini,
# pour éviter un DATA_DIR cassé du type /home//data
check-env:
	@if [ -z "$(LOGIN)" ]; then \
		echo "srcs/.env introuvable ou LOGIN non défini."; \
		echo "Fais d'abord : cp srcs/.env.example srcs/.env puis édite-le."; \
		exit 1; \
	fi

# ------------------------------------------------------------
# Préparation (dossiers + secrets)
# ------------------------------------------------------------

# Crée les dossiers de volumes AVANT de lancer les conteneurs.
# Nécessaire car ce sont des named volumes pointant vers un chemin
# hôte fixe (driver_opts type=none,bind) : si le dossier n'existe pas,
# Docker le crée lui-même, souvent avec des permissions inattendues.
prepare: check-env
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

# Génère les secrets uniquement s'ils n'existent pas déjà (idempotent),
# pour ne pas casser des volumes MariaDB déjà initialisés avec l'ancien mot de passe.
secrets:
	@mkdir -p $(SECRETS_DIR)
	@for f in $(SECRET_FILES); do \
		if [ ! -s $(SECRETS_DIR)/$$f.txt ]; then \
			openssl rand -base64 16 > $(SECRETS_DIR)/$$f.txt; \
			echo "Secret généré : $$f.txt"; \
		fi \
	done

# ------------------------------------------------------------
# Cycle de vie des conteneurs
# ------------------------------------------------------------

build: prepare secrets
	$(COMPOSE) build

up: prepare secrets
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart: down up

# ------------------------------------------------------------
# Nettoyage
# ------------------------------------------------------------

# down + suppression des volumes nommés (perte des données via Docker)
clean: down
	$(COMPOSE) down -v

# clean + suppression des images du projet (scopé, rien d'autre touché)
fclean: clean
	$(COMPOSE) down --rmi all -v

# fclean + suppression physique et IRRÉVERSIBLE des données sur l'hôte
deepclean: check-env fclean
	@echo "⚠️  Suppression définitive et irréversible de $(DATA_DIR)"
	@read -p "Confirmer ? [y/N] " ans; \
	if [ "$$ans" = "y" ]; then \
		sudo sh -c 'rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress'; \
		docker rmi -f mariadb:v1 wordpress:v1 nginx:v1 2>/dev/null || true; \
		docker builder prune -a -f --filter "label=com.docker.compose.project=srcs" 2>/dev/null || docker builder prune -a -f; \
		echo "Données, images et cache supprimés."; \
	else \
		echo "Annulé."; \
	fi

re: fclean all

# ------------------------------------------------------------
# Monitoring
# ------------------------------------------------------------

ps:
	$(COMPOSE) ps

ps-full:
	@echo "=== ÉTAT DES CONTENEURS ==="
	@docker ps -a --filter "label=com.docker.compose.project=srcs" \
		--format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"
	@echo ""
	@echo "=== HEALTHCHECKS ==="
	@for c in $$($(COMPOSE) ps -q); do \
		name=$$(docker inspect --format='{{.Name}}' $$c | sed 's/^\///'); \
		health=$$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no healthcheck{{end}}' $$c); \
		restarts=$$(docker inspect --format='{{.RestartCount}}' $$c); \
		echo "$$name : $$health (restarts: $$restarts)"; \
	done
	@echo ""
	@echo "=== RESSOURCES (CPU/MEM live) ==="
	@docker stats --no-stream $$($(COMPOSE) ps -q) 2>/dev/null || echo "Aucun conteneur actif"
	@echo ""
	@echo "=== RÉSEAUX ==="
	@docker network inspect inception_network --format \
	'{{range .Containers}}{{$$.Name}} : {{.Name}} -> {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || echo "Réseau introuvable"
	@echo ""
	@echo "=== VOLUMES ==="
	@docker volume ls --filter "name=volume" --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}"
	@echo ""
	@echo "--- Chemins hôte réels (bind mount) ---"
	@for v in $$(docker volume ls --filter "name=volume" -q); do \
		device=$$(docker volume inspect $$v --format '{{ index .Options "device" }}' 2>/dev/null); \
		echo "$$v -> $${device:-N/A}"; \
	done
	@echo ""
	@echo "=== IMAGES DU PROJET ==="
	@docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | \
		grep -E "REPOSITORY|mariadb|wordpress|nginx"

# ------------------------------------------------------------
# Vérification de l'état complet (volumes/networks/containers + site)
# ------------------------------------------------------------

DOMAIN		:= $(LOGIN).42.fr

check: check-env
	@echo "=== VOLUMES ==="
	@docker volume ls
	@echo ""
	@echo "=== NETWORKS ==="
	@docker network ls
	@echo ""
	@echo "=== CONTAINERS ==="
	@docker ps -a
	@echo ""
	@echo "=== SITE ($(DOMAIN)) ==="
	@curl -Ik https://$(DOMAIN) || echo "Site injoignable"

# ------------------------------------------------------------
# Logs
# ------------------------------------------------------------

logs:
	$(COMPOSE) logs -f

logs-nginx:
	$(COMPOSE) logs -f nginx

logs-wordpress:
	$(COMPOSE) logs -f wordpress

logs-mariadb:
	$(COMPOSE) logs -f mariadb

.PHONY: all check-env prepare secrets build up down stop start restart clean fclean deepclean re ps ps-full check logs logs-nginx logs-wordpress logs-mariadb
