# Documentation Utilisateur (USER_DOC.md) — Projet Inception

Ce guide explique, en termes simples, comment utiliser, administrer et vérifier le bon fonctionnement de l'infrastructure **Inception**.

---

## 1. Services fournis par la stack

L'infrastructure est composée de trois services conteneurisés interconnectés :

### 1.1 NGINX — Reverse Proxy & TLS

NGINX agit comme l'unique point d'entrée de l'application sur le port `443`.

Ses principales responsabilités sont :

* Chiffrer et déchiffrer les communications via **TLSv1.2** et **TLSv1.3**.
* Utiliser un certificat **auto-signé**.
* Relayer les requêtes PHP vers le conteneur WordPress via le réseau interne Docker.

### 1.2 WordPress + PHP-FPM

Ce service constitue le moteur du site web.

Il permet de :

* Traiter l'application PHP via **PHP-FPM**.
* Gérer les fichiers du site WordPress.
* Communiquer avec la base de données MariaDB.
* Automatiser l'installation et la configuration initiale de WordPress grâce à **WP-CLI**.
* Créer automatiquement les utilisateurs nécessaires au premier lancement.

### 1.3 MariaDB

MariaDB est le système de gestion de base de données relationnelle utilisé par WordPress.

Il stocke notamment :

* Les articles.
* Les pages.
* Les utilisateurs.
* Les réglages de WordPress.

La base de données est isolée du réseau extérieur et n'est accessible qu'aux services autorisés via le réseau Docker.

---

## 2. Démarrer et arrêter le projet

### Démarrer le projet

Pour lancer l'infrastructure en arrière-plan :

```bash
make
```

### Arrêter le projet sans perdre les données

```bash
make down
```

### Redémarrer le projet

```bash
make restart
```

---

## 3. Accéder au site web et au panneau d'administration

### Configurer le nom de domaine local

Assurez-vous que le nom de domaine pointe vers votre machine virtuelle en ajoutant une entrée dans le fichier `/etc/hosts` de votre poste client :

```text
<IP_DE_LA_VM> hseffih.42.fr
```

Par exemple :

```text
127.0.0.1 hseffih.42.fr
```

### Accéder au site public

Ouvrez votre navigateur et rendez-vous à l'adresse :

```text
https://hseffih.42.fr
```

> **Note :** Le certificat TLS étant auto-signé, votre navigateur affichera probablement un avertissement de sécurité. Vous devrez accepter l'exception de sécurité pour continuer vers le site.

### Accéder à l'administration WordPress

Pour accéder au panneau d'administration WordPress, rendez-vous à :

```text
https://hseffih.42.fr/wp-admin
```

---

## 4. Localiser et gérer les identifiants

Pour des raisons de sécurité, les mots de passe ne sont jamais inscrits en clair dans le code source ou dans le dépôt Git.

### Où trouver les mots de passe ?

Les fichiers contenant les secrets sont stockés localement dans le dossier `secrets/`, à la racine du projet. Ce dossier est ignoré par Git.

Les fichiers disponibles sont :

* `secrets/db_password.txt` : mot de passe de l'utilisateur de la base de données.
* `secrets/db_root_password.txt` : mot de passe de l'utilisateur `root` de MariaDB.
* `secrets/wp_admin_password.txt` : mot de passe de l'administrateur WordPress.
* `secrets/wp_user_password.txt` : mot de passe du second utilisateur WordPress, avec le rôle **Author**.

### Consulter un mot de passe

Par exemple, pour afficher le mot de passe de l'administrateur WordPress :

```bash
cat secrets/wp_admin_password.txt
```

### Identifiants administrateur par défaut

Les informations de configuration sont définies dans `srcs/.env`.

* **Nom d'utilisateur administrateur :** `hseffih`
* **Email administrateur :** `hseffih@student.42.fr`

> Le nom d'utilisateur administrateur ne contient pas de terme interdit tel que `admin`.

---

## 5. Vérifier que les services fonctionnent correctement

### Vérification rapide

Utilisez la commande suivante :

```bash
make check
```

Cette commande permet notamment de vérifier :

* L'état des volumes Docker.
* L'état des réseaux.
* Les conteneurs actifs.
* L'accessibilité du site via un test `curl`.

### Vérification détaillée

Pour afficher l'état détaillé des services et des *healthchecks* :

```bash
make ps-full
```

Cette commande permet de vérifier que :

* Chaque conteneur est dans un état **healthy**.
* Les services ne redémarrent pas de manière inattendue.
* Le nombre de redémarrages reste stable, idéalement à `0`.
* Les ressources utilisées par les conteneurs peuvent être surveillées.

---

## 6. Résumé des commandes utiles

| Action                                  | Commande       |
| --------------------------------------- | -------------- |
| Démarrer le projet                      | `make`         |
| Arrêter les services                    | `make down`    |
| Redémarrer le projet                    | `make restart` |
| Vérifier rapidement l'infrastructure    | `make check`   |
| Afficher l'état détaillé des conteneurs | `make ps-full` |

---

## 7. Points importants

* Le site est accessible uniquement via **HTTPS** sur le port `443`.
* Le certificat TLS est **auto-signé**, ce qui peut provoquer un avertissement dans le navigateur.
* MariaDB n'est pas directement accessible depuis l'extérieur.
* Les données sont conservées dans des volumes Docker afin de survivre à l'arrêt ou au redémarrage des conteneurs.
* Les mots de passe sont stockés dans le dossier `secrets/` et ne doivent pas être ajoutés au dépôt Git.
* WordPress est configuré automatiquement lors de l'initialisation grâce à **WP-CLI**.

