# n8n Azure Deployment

## 📋 Description

Script de déploiement de n8n sur Azure VM. Chaque utilisateur lance le script sur sa propre machine avec son compte Azure.

## 🚀 Utilisation

### Prérequis

1. Installer Azure CLI :
```bash
brew update && brew install azure-cli
```

2. Se connecter à Azure :
```bash
az login
```

### Déploiement

1. Cloner le repo :
```bash
git clone <url-du-repo>
cd n8n-sur-ton-poste
```

2. Rendre le script exécutable :
```bash
chmod +x script.sh
```

3. Lancer le déploiement :
```bash
./script.sh
```

Le script va :
- ✅ Créer un groupe de ressources Azure
- ✅ Créer une VM Debian
- ✅ Afficher l'IP publique
- ✅ Vous connecter automatiquement en SSH

### Après la connexion SSH

Une fois connecté à la VM, installez n8n :

```bash
# Installation de Docker
sudo apt-get update
sudo apt-get install -y curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Installation de Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Création du docker-compose pour n8n
mkdir -p ~/n8n-data
cat > ~/docker-compose.yml << 'EOF'
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    volumes:
      - ./n8n-data:/home/node/.n8n
EOF

# Démarrage de n8n
sudo docker-compose up -d
```

## 🌐 Accès à n8n

Votre instance sera accessible sur : `http://VOTRE_IP:5678`

Les identifiants seront créés lors de la première connexion dans le navigateur.

## 🛠️ Technologies

- Azure VM (Debian 11)
- Docker & Docker Compose
- n8n


