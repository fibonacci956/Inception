# Documentation Développeur (`DEV_DOC.md`) — Projet Inception

Ce document décrit l'architecture technique, la mise en place de l'environnement, le cycle de vie des conteneurs et la gestion des données pour les développeurs travaillant sur le projet **Inception**.

---

## 1. Mise en place de l'environnement depuis zéro

### 1.1 Prérequis système

* Une machine Linux (**Debian/Ubuntu recommandé**) avec un utilisateur configuré, par exemple `hseffih`.
* **Docker Engine** version `24.x` ou supérieure.
* **Docker Compose V2**.
* `make`.
* `openssl`.

### 1.2 Fichier d'environnement

Copiez le fichier d'exemple et adaptez-le à votre environnement :

```bash
cp srcs/.env.example srcs/.env
```

Le fichier `srcs/.env` contient les variables de configuration non sensibles, telles que :

* Le login WordPress.
* Le nom de domaine.
* Les noms des bases de données.
* Les noms d'utilisateurs.

> Les informations sensibles, telles que les mots de passe, ne doivent pas être stockées directement dans le fichier `.env`.

### 1.3 Gestion des secrets

Les mots de passe sensibles ne doivent jamais être inscrits en clair dans le code source ou dans le fichier `.env`.

Le `Makefile` génère automatiquement les fichiers de secrets manquants dans le dossier `secrets/`.

Les fichiers concernés sont :

```text
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

---

## 2. Build et lancement du projet

Le projet est entièrement piloté par un `Makefile` situé à la racine du dépôt.

Celui-ci automatise notamment :

* La vérification de l'environnement.
* La création des répertoires nécessaires aux volumes.
* La génération des secrets manquants.
* La construction des images Docker.
* Le lancement des conteneurs avec Docker Compose.

### 2.1 Commandes principales du Makefile

| Commande             | Description                                                                                                                                                                          |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `make` ou `make all` | Vérifie l'environnement, crée les dossiers nécessaires, génère les secrets manquants, construit les images et lance les conteneurs en arrière-plan.                                  |
| `make down`          | Arrête et supprime les conteneurs ainsi que le réseau associé.                                                                                                                       |
| `make stop`          | Arrête les conteneurs sans les supprimer.                                                                                                                                            |
| `make start`         | Redémarre les conteneurs existants sans les recréer.                                                                                                                                 |
| `make restart`       | Effectue un cycle complet d'arrêt puis de redémarrage des services.                                                                                                                  |
| `make clean`         | Arrête les conteneurs et supprime les volumes nommés Docker associés au projet.                                                                                                      |
| `make fclean`        | Effectue un nettoyage approfondi : arrêt des services, suppression des volumes et suppression des images du projet.                                                                  |
| `make deepclean`     | Effectue un nettoyage critique et interactif : supprime les conteneurs et images du projet, puis efface physiquement le contenu du dossier `/home/hseffih/data/` après confirmation. |
| `make re`            | Exécute `make fclean` suivi de `make all` afin de reconstruire complètement le projet.                                                                                               |

---

## 3. Commandes utiles de gestion des conteneurs et des volumes

### 3.1 Vérification de l'état des conteneurs

Pour afficher l'état des services :

```bash
make ps
```

Pour obtenir davantage d'informations :

```bash
make ps-full
```

Ces commandes permettent notamment de vérifier l'état des conteneurs et, selon la configuration, le statut des **healthchecks**.

### 3.2 Consultation des logs

Pour suivre les logs d'un service spécifique :

```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
```

```bash
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

```bash
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

### 3.3 Accès interactif à un conteneur

Pour ouvrir un shell dans le conteneur WordPress :

```bash
docker exec -it srcs-wordpress-1 sh
```

> Le nom exact du conteneur peut varier selon la configuration Docker Compose.

Pour vérifier les noms des conteneurs en cours d'exécution :

```bash
docker ps
```

### 3.4 Inspection du réseau Docker

Pour inspecter le réseau interne du projet :

```bash
docker network inspect inception_network
```

Cette commande permet notamment de consulter :

* Les conteneurs connectés au réseau.
* Les adresses IP internes.
* Les paramètres réseau utilisés par Docker.

---

## 4. Emplacement et persistance des données

Afin de satisfaire les exigences de persistance du projet **Inception**, les données des services avec état (*stateful services*) sont stockées hors des conteneurs, directement sur la machine hôte.

### 4.1 Emplacement des données sur l'hôte

Les données sont stockées dans les répertoires suivants :

```text
/home/hseffih/data/
├── mariadb/
│   └── Données de la base MariaDB
│
└── wordpress/
    └── Fichiers WordPress, contenus et uploads
```

Plus précisément :

| Service   | Emplacement sur l'hôte         |
| --------- | ------------------------------ |
| MariaDB   | `/home/hseffih/data/mariadb`   |
| WordPress | `/home/hseffih/data/wordpress` |

### 4.2 Mécanisme de persistance

Les volumes nommés Docker :

* `mariadb_volume`
* `wordpress_volume`

utilisent le driver `local` avec une configuration de type **bind mount**.

Le mécanisme repose notamment sur les options suivantes :

```yaml
driver: local
driver_opts:
  type: none
  o: bind
  device: /home/hseffih/data/...
```

Cette configuration permet d'associer directement un volume Docker à un répertoire physique présent sur la machine hôte.

### 4.3 Garanties de persistance

Grâce à cette architecture :

* Les données ne sont pas stockées uniquement à l'intérieur des conteneurs.
* La suppression ou la recréation des conteneurs n'entraîne pas automatiquement la perte des données présentes sur l'hôte.
* Les données MariaDB et WordPress restent accessibles tant que les répertoires correspondants sur l'hôte ne sont pas supprimés.

> **Attention :** la commande `make deepclean` supprime physiquement le contenu du dossier `/home/hseffih/data/` après confirmation. Cette opération entraîne donc la suppression définitive des données persistantes du projet.

---

## 5. Cycle de vie simplifié du projet

Le cycle de vie standard du projet peut être résumé comme suit :

```text
make
  │
  ├── Vérification de l'environnement
  │
  ├── Création des répertoires de données
  │
  ├── Génération des secrets manquants
  │
  ├── Build des images Docker
  │
  └── Lancement des services
          │
          ├── NGINX
          ├── WordPress
          └── MariaDB
```

Les données persistantes restent stockées sur l'hôte :

```text
Conteneur MariaDB ──────► /home/hseffih/data/mariadb
Conteneur WordPress ────► /home/hseffih/data/wordpress
```

Cette séparation entre les conteneurs et les données persistantes permet de reconstruire l'environnement applicatif sans perdre les données, tant que les répertoires de persistance de l'hôte ne sont pas supprimés.

