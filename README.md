*This project has been created as part of the 42 curriculum by **hseffih**.*

## Description

**Inception** est un projet d'administration système de l'école 42 qui vise à approfondir la compréhension de la conteneurisation via Docker.

L'objectif est de concevoir, configurer et déployer une infrastructure web complète, isolée et sécurisée, composée de plusieurs services conteneurisés interconnectés :

* **NGINX**
* **WordPress + PHP-FPM**
* **MariaDB**

L'ensemble de l'architecture repose sur des images construites sur mesure à partir d'**Alpine Linux `3.23.5`**, sans utiliser de services prêts à l'emploi ni le tag `latest`.

Le trafic entrant est strictement filtré via un unique reverse proxy **NGINX**, exposé sur le port `443` en **HTTPS**, utilisant exclusivement les protocoles sécurisés :

* `TLSv1.2`
* `TLSv1.3`

---

# Instructions

## Prérequis

Avant de lancer le projet, vous aurez besoin de :

- **Docker**
  - [Installation de Docker sur Linux](https://docs.docker.com/engine/install/)
  - [Installation de Docker Desktop sur Windows](https://docs.docker.com/desktop/setup/install/windows-install/)

- **Docker Compose V2**
  - Docker Compose V2 est inclus avec Docker Desktop sur Windows.
  - Sur Linux, vous pouvez suivre la [documentation officielle de Docker Compose](https://docs.docker.com/compose/install/).

- **Un accès sudo sous Linux**, nécessaire pour la gestion des dossiers hôtes utilisés par les volumes.
  - [Documentation sudo](https://www.sudo.ws/docs/)

### Compatibilité Windows

Le projet peut être lancé sur :

- **Linux**, avec Docker, Docker Compose V2 et `sudo` installés.
- **Windows**, à condition d'utiliser **Docker Desktop avec le moteur Linux et WSL2** activé.
  - [Documentation WSL2](https://learn.microsoft.com/windows/wsl/install)
  - [Documentation Docker Desktop avec WSL2](https://docs.docker.com/desktop/features/wsl/)

> **Remarque :** Une machine virtuelle Linux (VirtualBox, UTM, etc.) n'est pas nécessaire si Docker Desktop avec WSL2 est correctement configuré sous Windows.

## Installation et lancement rapide

### 1. Cloner le dépôt

Clonez le dépôt puis placez-vous à sa racine :

```bash
git clone <repository-url>
cd inception
```

### 2. Configurer les variables d'environnement

Copiez le fichier d'exemple :

```bash
cp srcs/.env.example srcs/.env
```

Éditez ensuite le fichier `.env` et renseignez notamment :

* votre `LOGIN`
* votre `DOMAIN_NAME`

Par exemple :

```env
LOGIN=hseffih
DOMAIN_NAME=hseffih.42.fr
```

### 3. Lancer l'infrastructure

Utilisez le `Makefile` pour construire et démarrer l'ensemble de l'infrastructure.

Cette commande prépare également les volumes et génère automatiquement les secrets nécessaires :

```bash
make
```

### 4. Configurer le domaine local

Ajoutez l'alias de domaine dans le fichier `/etc/hosts` de la machine hôte :

```plaintext
127.0.0.1 hseffih.42.fr
```

### 5. Accéder au site

Ouvrez votre navigateur et accédez à :

```text
https://hseffih.42.fr
```

---

# Resources & Usage de l'IA

## Documentation & références classiques

Les ressources suivantes ont été utilisées pour la conception et l'implémentation du projet :

* Alpine Linux Documentation
* Docker Documentation & Compose Specification
* NGINX Admin Guide
* MariaDB Knowledge Base
* WP-CLI Official Documentation

## Description de l'usage de l'IA par tâche

Dans le cadre de ce projet, l'intelligence artificielle a été utilisée comme un **assistant technique** afin d'optimiser certaines phases de développement, conformément aux directives pédagogiques.

Son utilisation s'est principalement concentrée sur :

* la réduction des tâches répétitives ;
* l'exploration de choix architecturaux ;
* l'analyse de comportements techniques ;
* la revue et la structuration de code ;
* la rédaction de documentation.

### Recherche et conception des réseaux & DNS interne

L'IA a été utilisée pour analyser le comportement des différents drivers réseau Docker :

* `bridge`
* `host`
* `none`

Elle a également servi à explorer et valider le fonctionnement du mini-serveur DNS interne de Docker, accessible depuis les conteneurs via :

```text
127.0.0.11
```

### Sécurité TLS & analyse des Cipher Suites

L'IA a été utilisée pour étudier les différentes versions de TLS et comparer les protocoles modernes aux versions obsolètes ou vulnérables.

Cela a notamment permis de documenter :

* l'utilisation de `TLSv1.2` et `TLSv1.3` ;
* l'abandon des protocoles SSL obsolètes ;
* les vulnérabilités historiques telles que **POODLE** ;
* le durcissement de la configuration TLS ;
* la configuration de `ssl_ciphers` ;
* la désactivation des tickets de session lorsque cela était pertinent.

### Automatisation et robustesse des scripts d'entrypoint

L'IA a servi à structurer la logique d'initialisation des services afin de garantir une exécution robuste et idempotente.

Cela concerne notamment :

* **MariaDB**

  * initialisation avec `mysql_install_db` ;
  * démarrage temporaire du serveur ;
  * création automatisée de la base de données et des utilisateurs.

* **WordPress**

  * utilisation de `wp-cli` ;
  * gestion des tentatives de connexion (*retries*) ;
  * vérifications de disponibilité des services ;
  * prévention des réinstallations inutiles.

### Rédaction et structuration de la documentation

L'IA a également été utilisée pour améliorer la structuration et la mise en forme des documents techniques du projet :

* `README.md`
* `DEV_DOC.md`
* `USER_DOC.md`

Elle a notamment aidé à formaliser les comparatifs architecturaux demandés dans le cadre du projet.

---

# Project Description & Choix d'architecture

L'infrastructure repose sur un fichier `docker-compose.yml` centralisant les trois services principaux :

* **NGINX**
* **WordPress**
* **MariaDB**

Ces services communiquent via un réseau bridge personnalisé nommé :

```text
inception_network
```

Cette architecture permet :

* l'isolation des services ;
* la communication interne entre conteneurs ;
* la résolution dynamique des noms de services ;
* la limitation de l'exposition réseau ;
* la persistance des données.

---

# Comparatifs exigés

## 1. Virtual Machines vs Docker

### Virtual Machine

Une machine virtuelle virtualise une machine physique complète.

Elle comprend généralement :

* du matériel virtualisé ou émulé ;
* un système d'exploitation complet ;
* son propre noyau ;
* une pile système indépendante ;
* un hyperviseur permettant son exécution.

Chaque VM possède donc son propre environnement complet, ce qui entraîne :

* une consommation plus importante de RAM ;
* une consommation CPU plus élevée ;
* un espace disque plus conséquent ;
* un temps de démarrage généralement plus long.

### Docker

Docker repose sur une virtualisation au niveau du système d'exploitation.

Les conteneurs utilisent notamment :

* les **namespaces** pour l'isolation ;
* les **cgroups** pour la gestion des ressources.

Contrairement aux machines virtuelles, les conteneurs partagent le noyau du système hôte.

Cela permet :

* un démarrage rapide ;
* une consommation réduite de ressources ;
* une meilleure densité de services ;
* une isolation adaptée aux applications et services.

### Choix dans le projet

Le projet combine les deux approches :

1. Une **machine virtuelle** héberge l'environnement global, conformément aux exigences pédagogiques du cursus 42.
2. À l'intérieur de cette machine virtuelle, **Docker** isole chaque service :

```text
VM
└── Docker
    ├── NGINX
    ├── WordPress + PHP-FPM
    └── MariaDB
```

Cette approche permet de bénéficier à la fois :

* de l'isolation globale offerte par la VM ;
* de la légèreté et de la modularité des conteneurs Docker.

---

## 2. Secrets vs Environment Variables

### Environment Variables

Les variables d'environnement sont principalement utilisées pour transmettre des informations de configuration aux applications.

Elles sont adaptées aux données non sensibles, telles que :

* le nom de domaine ;
* le nom de la base de données ;
* les noms d'utilisateurs ;
* les paramètres de configuration générale.

Exemples :

```env
DOMAIN_NAME=hseffih.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

Les variables d'environnement ne doivent pas être utilisées pour stocker des secrets sensibles lorsque ceux-ci peuvent être exposés via :

* les fichiers de configuration ;
* l'inspection des conteneurs ;
* les processus ;
* des erreurs de configuration ou de journalisation.

### Docker Secrets

Les secrets permettent de fournir des informations sensibles aux services sans les placer directement dans les variables d'environnement ou dans les images.

Les secrets sont accessibles dans les conteneurs sous forme de fichiers, par exemple :

```text
/run/secrets/
```

Ils peuvent contenir :

* des mots de passe ;
* des identifiants sensibles ;
* des clés privées ;
* d'autres données confidentielles.

### Choix dans le projet

Le projet utilise deux mécanismes distincts.

#### Configuration publique

Le fichier `.env` contient les informations non sensibles :

```env
DOMAIN_NAME=hseffih.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

#### Informations sensibles

Les mots de passe sont stockés dans des fichiers de secrets :

```text
secrets/
├── db_root_password.txt
├── db_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

Ces secrets sont ensuite montés dans les conteneurs sous :

```text
/run/secrets/
```

Cette séparation permet de distinguer clairement :

* la **configuration** ;
* les **données sensibles**.

---

## 3. Docker Network : Custom Bridge vs Host Network

### Host Network

Avec le mode réseau :

```text
--network host
```

le conteneur utilise directement la pile réseau de la machine hôte.

Les conséquences sont notamment :

* absence d'isolation réseau entre le conteneur et l'hôte ;
* utilisation directe des interfaces réseau de l'hôte ;
* absence de nécessité de mapping de ports dans certains cas.

Cependant, cette approche réduit fortement l'isolation et n'est pas adaptée à l'architecture demandée pour ce projet.

### Custom Bridge Network

Un réseau bridge personnalisé crée un réseau virtuel privé permettant aux conteneurs de communiquer entre eux.

Les services bénéficient :

* d'adresses IP internes ;
* d'une isolation réseau ;
* d'une résolution DNS interne ;
* de la possibilité de communiquer via les noms de services.

Par exemple :

```text
wordpress
mariadb
nginx
```

### Choix dans le projet

Le projet utilise exclusivement un réseau bridge personnalisé :

```yaml
networks:
  inception_network:
    driver: bridge
```

L'architecture réseau peut être représentée ainsi :

```text
Internet / Navigateur
        │
        │ HTTPS :443
        ▼
      NGINX
        │
        ├──────────► WordPress + PHP-FPM
        │
        └──────────► MariaDB
```

Seul **NGINX** expose le port :

```text
443
```

vers la machine hôte.

Les services **WordPress** et **MariaDB** ne sont pas directement accessibles depuis l'extérieur.

Ils communiquent uniquement à travers le réseau interne Docker.

---

## 4. Docker Volumes vs Bind Mounts

### Bind Mounts

Un bind mount relie directement un dossier de la machine hôte à un chemin situé dans le conteneur.

Exemple conceptuel :

```text
Machine hôte
/home/user/data
        │
        ▼
Conteneur
/var/lib/mysql
```

Cette approche dépend directement :

* de la structure du système hôte ;
* des chemins utilisés ;
* des permissions du système de fichiers.

Elle peut également rendre l'environnement moins portable et entraîner des problèmes de permissions.

### Docker Volumes

Les volumes Docker permettent de gérer la persistance des données indépendamment du cycle de vie des conteneurs.

Ils permettent notamment :

* de conserver les données après la suppression d'un conteneur ;
* de séparer les données de l'image ;
* de gérer plus facilement le stockage persistant.

Dans ce projet, les volumes sont configurés pour répondre à la contrainte imposant le stockage des données sous :

```text
/home/<login>/data/
```

Le volume Docker est associé à un chemin spécifique de l'hôte grâce à des options de montage.

### Choix dans le projet

Deux volumes principaux sont utilisés :

```text
/home/hseffih/data/
├── mariadb/
└── wordpress/
```

Ils assurent la persistance des données de :

* **MariaDB**
* **WordPress**

Exemple de configuration :

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

Cette configuration permet :

* d'utiliser des volumes déclarés dans Docker Compose ;
* de conserver les données sur la machine hôte ;
* de respecter le chemin imposé par le sujet ;
* de garantir la persistance des données même après la recréation des conteneurs.

---

# Architecture globale

L'architecture finale peut être résumée ainsi :

```text
                        ┌─────────────────────┐
                        │    Navigateur       │
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

# Sécurité

Les principaux mécanismes de sécurité mis en place sont :

* Utilisation exclusive de **HTTPS**.
* Exposition uniquement du port `443`.
* Utilisation de `TLSv1.2` et `TLSv1.3`.
* Désactivation des protocoles SSL obsolètes.
* Isolation des services via un réseau bridge Docker personnalisé.
* Absence d'exposition directe de WordPress et MariaDB.
* Séparation des variables de configuration et des données sensibles.
* Utilisation de secrets pour les mots de passe.
* Images construites localement à partir d'Alpine Linux.
* Absence d'utilisation du tag `latest`.
* Persistance des données via des volumes Docker.

---

## Auteur

**hseffih**

Projet réalisé dans le cadre du cursus de **42**.

