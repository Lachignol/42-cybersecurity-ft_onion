# 🧅 ft_onion - Hidden Service Tor HTTP

> Hidden service Tor avec serveur web HTTP et accès SSH

**[🇬🇧 English version](./README.en.md)**

## 📚 Table des matières

- [Description](#-description)
- [Prérequis](#-prérequis)
- [Installation pas à pas](#-installation-pas-à-pas)
- [Utilisation](#-utilisation)
- [Configuration avancée](#-configuration-avancée)
- [Accès au service](#-accès-au-service)
- [Commandes disponibles](#-commandes-disponibles)
- [Troubleshooting](#-troubleshooting)
- [Sécurité](#-sécurité)

---

## 📖 Description

Ce projet crée un **Hidden Service Tor** complet avec :
- 🌐 Serveur web **nginx** (HTTP port 80)
- 🔐 Serveur **SSH** (port 4242)
- 🧅 Anonymisation via **Tor**
- 🐳 Tout containerisé avec **Docker**

### Architecture

```
Internet (Tor) → Hidden Service .onion → Container Docker
                                         ├── nginx (web HTTP:80)
                                         ├── SSH (4242)
                                         └── Tor daemon
```

---

## ✅ Prérequis

Avant de commencer, assurez-vous d'avoir :

### Logiciels requis

- **Docker** installé et lancé
  ```bash
  docker --version  # Doit afficher une version
  ```

- **Make** installé
  ```bash
  make --version    # Doit afficher une version
  ```

- **OpenSSH** (pour générer les clés)
  ```bash
  ssh-keygen --help # Doit afficher l'aide
  ```

### Navigateur Tor (pour tester)

- Télécharger [Tor Browser](https://www.torproject.org/download/)

---

## 🚀 Installation pas à pas

### Étape 1 : Se placer dans le projet

```bash
cd 42-cybersecurity-ft_onion
```

### Étape 2 : Générer les clés SSH

**Important :** Cette étape est **obligatoire** avant de build !

```bash
make generate_key
```

**Résultat attendu :**
```
✅ Clé générée dans ./ssh_key_folder/
⚠️  ATTENTION: Clé privée NON protégée par passphrase !
   Clé privée: ./ssh_key_folder/ft_onion_key
   Clé publique: ./ssh_key_folder/ft_onion_key.pub
```

**Qu'est-ce que ça fait ?**
- Crée une paire de clés SSH ED25519
- Stocke la clé publique dans `./ssh_key_folder/ft_onion_key.pub`
- Stocke la clé privée dans `./ssh_key_folder/ft_onion_key`

### Étape 3 : 

#### Methode 1 : La plus simple installation et lancement du container ainsi que affichage des adresses web et ssh automatiquement

```bash
make
```
Vous pouvez directement passer a [Utilisation](#utilisation)

#### Methode 2 : Build de l'image Docker

```bash
make build
```

**Durée :** ~2-5 minutes (selon votre connexion)

**Qu'est-ce que ça fait ?**
- Télécharge Ubuntu 22.04
- Installe nginx, tor, openssh-server, vim
- Configure tous les services
- Copie votre clé SSH publique

**Résultat attendu :**
```
Successfully tagged ft_onion:latest
```

### Étape 4 : Lancer le container

```bash
make run
```

**Résultat attendu :**
```
<container_id>
```

Le container tourne maintenant en arrière-plan (mode détaché `-d`).

### Étape 5 : Récupérer les adresses .onion

#### Pour le site web :

```bash
make addr
```

**Résultat attendu :**
```
Address of website:
abc123def456ghi789jkl.onion
```

#### Pour le SSH :

```bash
make addr_ssh
```

**Résultat attendu :**
```
Address of ssh:
xyz789uvw456rst123def.onion
```

**💡 Note :** Ces adresses sont **uniques** et changent à chaque nouveau build.

---

## 🎯 Utilisation

### Accéder au site web

1. **Ouvrir Tor Browser**
2. **Copier l'adresse .onion** du site (depuis `make addr`)
3. **Coller dans Tor Browser :**
   ```
   http://votre-adresse.onion
   ```

Vous devriez voir la page HTML simple : "test"

### Se connecter en SSH

1. **Récupérer l'adresse SSH .onion :**
   ```bash
   make addr_ssh
   ```

2. **Configurer torify ou ProxyCommand dans ~/.ssh/config :**

   **Option A - Avec torify (simple) :**
   ```bash
   torify ssh -i ./ssh_key_folder/ft_onion_key votreNomUtilisateur@votre-adresse-ssh.onion -p 4242
   ```

   **Option B - Avec ProxyCommand (recommandé) :**
   
   Ajouter dans `~/.ssh/config` :
   ```
   Host ft-onion
       HostName votre-adresse-ssh.onion
       User votreNomUtilisateur
       Port 4242
       IdentityFile /chemin/absolu/vers/ssh_key_folder/ft_onion_key
       # port 9050 pour tor sans passer par le browser
       # ProxyCommand nc -X 5 -x 127.0.0.1:9050 %h %p
	   # port 9150 pour tor par tor browser
       ProxyCommand nc -xlocalhost:9150 %h %p
   ```

   Puis connectez-vous :
   ```bash
   ssh ft-onion
   ```

3. **Vous êtes connecté !**
   ```bash
   votreNomUtilisateur@<container_id>:~$
   ```

### Explorer le container

```bash
make bash
```

Vous obtenez un shell root dans le container :

```bash
root@<container_id>:/#
```

**Commandes utiles dans le container :**

```bash
# Vérifier que nginx tourne
curl http://localhost:80

# Vérifier que Tor tourne
pgrep tor

# Voir les logs Tor
cat /var/log/tor/notices.log

# Voir la config nginx
cat /etc/nginx/sites-available/default

# Voir la config SSH
cat /etc/ssh/sshd_config
```

---

## ⚙️ Configuration avancée

### Personnaliser les paramètres

Créez un fichier `.env` à la racine du projet :

```bash
nano .env
```

**Contenu du .env :**
```env
SSH_USER=MonNom
SSH_PORT=2222
WEB_PORT=8080
```

**Puis rebuild :**
```bash
make re
```

### Variables disponibles

| Variable | Défaut | Description |
|----------|--------|-------------|
| `SSH_USER` | Lachignol | Nom d'utilisateur SSH |
| `SSH_PORT` | 4242 | Port SSH interne |
| `WEB_PORT` | 80 | Port web interne |

---

## 📋 Commandes disponibles

### Commandes principales

```bash
# Build l'image Docker
make build

# Lance le container
make run

# Build + Run + Affiche les adresses
make all

# Affiche l'adresse web .onion
make addr

# Affiche l'adresse SSH .onion
make addr_ssh

# Accès shell au container
make bash
```

### Commandes de nettoyage

```bash
# Arrête le container
make clean

# Supprime container + image
make fclean

# Rebuild complet (fclean + build)
make re
```

### Commandes de génération

```bash
# Génère les clés SSH (à faire avant le build)
make generate_key
```

---

## 🔍 Troubleshooting

### Problème : "No such file or directory: ./public_key_folder/ft_onion_key.pub"

**Solution :**
```bash
make generate_key
```

Vous avez oublié de générer les clés SSH avant le build.

---

### Problème : Le container démarre puis s'arrête immédiatement

**Diagnostic :**
```bash
docker logs ft_onion
```

**Solutions possibles :**

1. **SSH n'a pas démarré :**
   ```
   ERREUR: SSH n'a pas démarré
   ```
   → Vérifiez que la clé SSH est valide

2. **Tor n'a pas démarré :**
   ```
   ERREUR: Tor n'a pas démarré
   ```
   → Vérifiez les permissions `/var/lib/tor`

---

### Problème : "Connection refused" lors de la connexion SSH

**Vérifications :**

1. **Le container tourne ?**
   ```bash
   docker ps | grep ft_onion
   ```

2. **SSH écoute sur le bon port ?**
   ```bash
   make bash
   netstat -tlnp | grep sshd
   ```

3. **Vous utilisez la bonne adresse .onion ?**
   ```bash
   make addr_ssh
   ```

4. **Tor Browser ou Tor est lancé localement ?**
   ```bash
   # Sur macOS/Linux
   brew services list | grep tor
   # ou
   systemctl status tor
   ```

---

### Problème : "Permission denied (publickey)"

**Solution :**

Vérifiez que vous utilisez la bonne clé privée :
```bash
ssh -i ./ssh_key_folder/ft_onion_key -v votreNomUtilisateur@adresse.onion -p 4242
```

L'option `-v` affiche les détails de connexion.

---

### Problème : Le site web ne charge pas dans Tor Browser

**Vérifications :**

1. **L'adresse .onion est correcte ?**
   ```bash
   make addr
   ```

2. **Nginx fonctionne dans le container ?**
   ```bash
   make bash
   curl http://localhost:80
   ```
   Vous devriez voir le HTML.

3. **Tor Browser est bien configuré ?**
   - Vérifiez que vous êtes connecté au réseau Tor (icône oignon verte)

---

## 🔐 Sécurité

### Points de sécurité implémentés ✅

- ✅ **Authentification SSH par clé uniquement** (pas de password)
- ✅ **SSH écoute sur 127.0.0.1** (pas d'exposition directe)
- ✅ **Permissions fichiers SSH strictes** (700/600)
- ✅ **Headers de sécurité HTTP** (X-Frame-Options, CSP, etc.)
- ✅ **Limitation tentatives SSH** (3 max)
- ✅ **Timeout de connexion SSH** (30 secondes)
- ✅ **Déconnexion après inactivité** (10 minutes)
- ✅ **Logs Tor activés** (débogage)
- ✅ **Limitation bande passante Tor** (anti-saturation)
- ✅ **Healthcheck Docker** (monitoring)

### Recommandations

⚠️ **Clé SSH sans passphrase** : La clé privée n'est pas protégée par mot de passe. Gardez-la secrète !

⚠️ **Environnement de test** : Ce projet est éducatif. Pour production, renforcez la sécurité.

---

## 📁 Structure du projet

```
cybersecurity-ft_onion/
├── dockerfile                    # Configuration Docker
├── entrypoint.sh                 # Script de démarrage des services
├── Makefile                      # Commandes make
├── .gitignore                    # Fichiers ignorés par git
├── README.md                     # Ce fichier
│
├── ssh_key_folder/            # Clés SSH
│   ├── .gitkeep                  # (tracké)
│   ├── ft_onion_key              # Clé privée (généré, ignoré)
│   └── ft_onion_key.pub          # Clé publique (généré, ignoré)
│
├── html/                         # Site web statique
│   └── index.html
│
├── nginx.conf.template           # Template nginx (port dynamique)
├── sshd_config.template          # Template SSH (port dynamique)
├── torrc.template                # Template Tor (ports dynamiques)
│
└── ssh_config(...)               # Exemple config SSH client
```

---

## 🌐 Fonctionnement de Tor

### Comment ça marche ?

1. **Tor génère une adresse .onion** unique lors du premier démarrage
2. **Le daemon Tor** route le trafic à travers 3 relais aléatoires
3. **L'adresse .onion** est stockée dans `/var/lib/tor/web/hostname`
4. **Les visiteurs** se connectent via le réseau Tor
5. **Tor redirige** vers nginx (port 80) ou SSH (port 4242) en local

### Schéma du flux

```
Utilisateur
    ↓
Tor Browser
    ↓
Réseau Tor (3 relais)
    ↓
Votre adresse .onion
    ↓
Container Docker
    ↓
nginx (HTTP:80) ou SSH (4242)
```

---

## 🎓 Concepts appris

En réalisant ce projet, vous apprenez :

- 🐳 **Docker** : Containerisation d'applications
- 🧅 **Tor** : Hidden Services et anonymisation
- 🌐 **nginx** : Configuration serveur web
- 🔐 **SSH** : Authentification par clé publique
- 🛠️ **Make** : Automatisation de tâches
- 📝 **Templates** : Substitution dynamique avec sed
- 🔒 **Sécurité** : Hardening SSH, headers HTTP, permissions

---

## 📖 Ressources

- [Documentation Tor](https://www.torproject.org/docs/)
- [Documentation nginx](https://nginx.org/en/docs/)
- [Documentation SSH](https://www.openssh.com/manual.html)
- [Documentation Docker](https://docs.docker.com/)

---

## ⚖️ Licence

Projet éducatif - 42 School

---

**Auteur :** Lachignol
**Projet :** ft_onion (version HTTP)  
**Date :** 2026
