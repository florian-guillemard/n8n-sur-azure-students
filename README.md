# n8n Azure Deployment - Automatisation Complète

## 📋 Description

Ce projet permet de déployer automatiquement une instance n8n sur Azure en utilisant Terraform, Docker et Git. Avec un simple script, les utilisateurs peuvent créer leur propre instance n8n en quelques minutes.

## 🎯 Objectif

Automatiser le déploiement d'instances n8n personnalisées sur Azure avec une configuration minimale. Chaque utilisateur peut avoir sa propre instance isolée et sécurisée.

## 🛠️ Technologies Utilisées

- **Azure**: Hébergement cloud (Container Instances, Storage, Virtual Network)
- **Terraform**: Infrastructure as Code pour provisionner les ressources Azure
- **Docker**: Conteneurisation de n8n
- **Git**: Versioning et distribution du projet
- **n8n**: Plateforme d'automatisation workflow

## 📦 Prérequis

Avant de commencer, assurez-vous d'avoir installé:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (version 2.30+)
- [Terraform](https://www.terraform.io/downloads) (version 1.0+)
- [Docker](https://docs.docker.com/get-docker/) (version 20.10+)
- [Git](https://git-scm.com/downloads)
- Un compte Azure avec un abonnement actif

## 🚀 Installation Rapide

### 1. Cloner le repository

```bash
git clone https://github.com/votre-organisation/n8n-azure-deploy.git
cd n8n-azure-deploy
```

### 2. Configurer Azure CLI

```bash
az login
az account set --subscription "VOTRE_SUBSCRIPTION_ID"
```

### 3. Lancer le déploiement automatique

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Le script vous demandera:
- **Nom d'utilisateur**: Votre identifiant pour n8n
- **Mot de passe**: Mot de passe sécurisé (minimum 12 caractères)
- **Région Azure**: Par défaut `westeurope`
- **Nom de l'instance**: Nom unique pour votre déploiement

## 📁 Structure du Projet

```
n8n-azure-deploy/
├── README.md                    # Documentation principale
├── .gitignore                   # Fichiers à ignorer
├── terraform/
│   ├── main.tf                  # Configuration principale Terraform
│   ├── variables.tf             # Variables d'entrée
│   ├── outputs.tf               # Sorties après déploiement
│   └── terraform.tfvars.example # Exemple de configuration
├── docker/
│   ├── Dockerfile               # Image Docker personnalisée n8n
│   └── docker-compose.yml       # Composition pour tests locaux
└── scripts/
    ├── deploy.sh                # Script de déploiement automatique
    ├── destroy.sh               # Script de suppression
    └── update.sh                # Script de mise à jour
```

## ⚙️ Configuration Détaillée

### Variables Terraform

Créez un fichier `terraform/terraform.tfvars`:

```hcl
resource_group_name = "rg-n8n-prod"
location            = "westeurope"
instance_name       = "mon-n8n"
n8n_username        = "admin"
n8n_password        = "VotreMotDePasseSecurise123!"
```

### Variables d'environnement n8n

Le déploiement configure automatiquement:
- `N8N_BASIC_AUTH_ACTIVE=true`
- `N8N_BASIC_AUTH_USER`
- `N8N_BASIC_AUTH_PASSWORD`
- `N8N_HOST` (généré automatiquement)
- `N8N_PROTOCOL=https`
- `WEBHOOK_URL` (généré automatiquement)

## 🔐 Sécurité

- ✅ Authentification basique activée par défaut
- ✅ HTTPS configuré automatiquement
- ✅ Stockage Azure sécurisé pour les données
- ✅ Variables sensibles chiffrées dans Terraform
- ✅ Network Security Groups configurés
- ⚠️ **Important**: Ne commitez JAMAIS vos identifiants dans Git

## 📊 Coûts Azure Estimés

Estimation mensuelle pour une instance standard:
- **Azure Container Instances**: ~30-50€/mois
- **Azure Storage**: ~5-10€/mois
- **Réseau/Bande passante**: ~5€/mois

**Total estimé**: 40-65€/mois (variable selon l'utilisation)

## 🔄 Commandes Utiles

### Déployer une instance
```bash
./scripts/deploy.sh
```

### Mettre à jour une instance existante
```bash
./scripts/update.sh
```

### Supprimer une instance
```bash
./scripts/destroy.sh
```

### Vérifier l'état
```bash
cd terraform
terraform show
```

### Voir les logs n8n
```bash
az container logs --resource-group rg-n8n-prod --name n8n-container
```

## 🐛 Dépannage

### Erreur d'authentification Azure
```bash
az login --use-device-code
az account list
```

### Port déjà utilisé (en local)
```bash
docker ps
docker stop $(docker ps -q)
```

### Instance n8n inaccessible
Vérifiez les NSG rules:
```bash
az network nsg rule list --resource-group rg-n8n-prod --nsg-name n8n-nsg
```

## 📝 Roadmap

- [ ] Support multi-régions automatique
- [ ] Backup automatique des workflows
- [ ] Monitoring avec Azure Monitor
- [ ] Auto-scaling selon la charge
- [ ] Support pour PostgreSQL externe
- [ ] CI/CD avec GitHub Actions

## 🤝 Contribution

Les contributions sont les bienvenues! 

1. Fork le projet
2. Créez votre branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/votre-organisation/n8n-azure-deploy/issues)
- **Documentation n8n**: [docs.n8n.io](https://docs.n8n.io)
- **Documentation Azure**: [docs.microsoft.com](https://docs.microsoft.com/azure)

## ✨ Remerciements

- Équipe n8n pour leur excellente plateforme
- Communauté Terraform
- Microsoft Azure

---

**Note**: Ce projet n'est pas officiellement affilié à n8n.io
