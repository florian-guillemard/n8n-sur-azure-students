# README — Automatisation complète du déploiement et configuration de n8n sur Azure

Ce projet contient 2 scripts Bash distincts, complémentaires, accompagnant un déploiement automatisé d'un serveur n8n sur une machine virtuelle Azure, suivi d'une configuration simple via l'interface n8n.

## Création d’un compte Azure for Students

Pour bénéficier des crédits gratuits et des services Azure spécifiques aux étudiants, suivez ces étapes pour créer votre compte Azure for Students :
	
	1.	Rendez-vous sur la page officielle Azure for Students : "https://azure.microsoft.com/fr-fr/free/students"  
	
<img width="1512" height="759" alt="Screenshot 2025-10-30 at 10 37 43" src="https://github.com/user-attachments/assets/41892580-2328-4791-a16e-e62e8323ccae" />

	2.	Connectez-vous avec votre adresse mail scolaire fourni spécifiquement pour ce projet en cliquant sur "COMMENCEZ GRATUITEMENT" :

		- Vous devrez vous connecter avec le compte supdevinci-edu.fr
		- Remplir les formulaires
    	- Prénom
    	- Nom
    	- Pays
    	- Nom de l’établissement scolaire : Sup de Vinci (Bordeaux)
    	- ….
		
<img width="557" height="779" alt="Screenshot 2025-10-30 at 10 43 40" src="https://github.com/user-attachments/assets/90697c63-ff7e-4c75-981a-e0b92ae8ea6b" />

	3.	Complétez le formulaire de vérification d’identité étudiante, validez votre statut en utilisant votre adresse
	mail fourni pour ce projet. 
	
<img width="766" height="751" alt="Screenshot 2025-10-30 at 10 42 40" src="https://github.com/user-attachments/assets/75144e1e-93e9-4578-b044-253a793c0b20" />

	4. Activez la vérification en deux étapes (2FA) pour renforcer la sécurité de votre compte. 
	Cette étape consiste à configurer une méthode d’authentification supplémentaire, comme 	l’application
	Microsoft Authenticator ou une vérification par téléphone.
	
<img width="494" height="419" alt="Screenshot 2025-10-30 at 10 39 54" src="https://github.com/user-attachments/assets/b692c9ef-be3c-44c9-bb80-2f12e7731364" />
<img width="810" height="544" alt="Screenshot 2025-10-30 at 10 40 09" src="https://github.com/user-attachments/assets/26f63f44-c438-4235-9990-b85d46656f2d" />
<img width="782" height="477" alt="Screenshot 2025-10-30 at 10 40 18" src="https://github.com/user-attachments/assets/ff3b50e6-8f6b-4143-8e86-75eb88a399e5" />
<img width="804" height="494" alt="Screenshot 2025-10-30 at 10 40 50" src="https://github.com/user-attachments/assets/701c5c2e-1468-417f-9d84-d22612c15ab5" />
<img width="891" height="434" alt="Screenshot 2025-10-30 at 10 40 59" src="https://github.com/user-attachments/assets/4426c262-c67c-47d7-ab1b-82eb095ac720" />

	
	5.	Une fois votre compte vérifié, vous recevrez un crédit gratuit valable 12 mois pour utiliser
	les services Azure. Vous pourrez renouveler cette offre tant que vous êtes étudiant.
	
<img width="1509" height="755" alt="Screenshot 2025-10-30 at 10 45 25" src="https://github.com/user-attachments/assets/36c54ae7-427b-467b-b90c-a8d6dffe533f" />

Ces étapes vous permettront d’accéder facilement à un environnement cloud pour vos projets et apprentissages.

---

## Aperçu des scripts

| Script | Description | Utilisateur cible |
|--------|-------------|-------------------|
| `deploy_n8n_azure.sh` | Déploie VM Azure Debian, installe Docker & n8n, ouvre les ports 
| `n8n_manager.sh` | Configure l'utilisateur n8n, gère clé API et workflows | 

---

## Script 1 – Déploiement Azure automatisé (`deploy_n8n_azure.sh`)

### Fonctionnalités principales

- Vérifie et installe Azure CLI si nécessaire
- Authentifie l'utilisateur sur Azure
- Récupère la liste des régions autorisées via la politique Azure
- Crée les ressources Azure nécessaires (Resource Group, réseau virtuel, sous-réseau, groupes de sécurité)
- Configure les règles du groupe de sécurité pour ouvrir SSH (ports 22 et 443) et le port 5678 de n8n
- Génère une paire de clés SSH locale pour la VM (`~/.ssh/n8n_azure`)
- Crée une machine virtuelle Debian 11 avec cloud-init :
  - Installe Docker
  - Lance automatiquement un conteneur n8n avec authentification basique (admin/admin123)
- Attend que le service n8n soit disponible sur le port 5678 de la VM
- Affiche les informations d'accès (IP publique, SSH, credentials par défaut)

### Comment utiliser

1. **Rendre le script exécutable :**
   `chmod +x deploy_n8n_azure.sh`

2. **Lancer le script :**
`./deploy_n8n_azure.sh`


3. **Se connecter à Azure** via l'interface ouverte dans le navigateur pour s'authentifier avec le compte fourni spécifiquement pour ce projet
<img width="1320" height="1230" alt="image" src="https://github.com/user-attachments/assets/f186ce55-cbf9-41d3-b6ab-117c86ce4b0a" />
	Retourner dans le terminal et choisissez le compte fourni précédemment, puis cliquez sur "entrée"
<img width="1239" height="373" alt="Screenshot 2025-10-30 at 11 21 22" src="https://github.com/user-attachments/assets/f1da2da8-52fb-4a41-a2ca-61c561aa99df" />


5. Le script s'occupe de tout le déploiement

6. À la fin, il affiche :
- L'adresse IP publique de la machine
- Les accès SSH
- L'URL n8n (ex: `http://<IP>:5678`)
<img width="1702" height="1126" alt="image" src="https://github.com/user-attachments/assets/1a19cfbe-b0ab-4d6e-be68-55c8e4f76499" />

### Nettoyage

Pour supprimer toutes les ressources Azure et les clés SSH associées :
`./deploy_n8n_azure.sh –cleanup`

---

## Script 2 – Gestion simple de n8n (`n8n_manager.sh`)

### Objectif

Après que la VM et n8n soient déployés, ce script sert à configurer proprement n8n sans intervention manuelle lourde.

### Fonctionnalités

- Créer un utilisateur administrateur n8n (en demandant IP, email, prénom, nom, mot de passe sécurisé)
- Enregistrer et réutiliser la clé API automatiquement
- Charger des workflows JSON dans n8n via API
- Mettre à jour ou supprimer la clé API

### Utilisation

1. **Rendre le script exécutable :**
chmod +x n8n_manager.sh

2. **Lancer le script :**
`./n8n_manager.sh`


3. **Suivre le menu interactif** :
4. 
[Lors du lancement de ce script, il faut en premier lieu choisir l'OPTION 1 pour configurer le compte administrateur]

- Option 1 : Créer un utilisateur
  
<img width="570" height="430" alt="image" src="https://github.com/user-attachments/assets/48533e7d-213a-41e0-b59c-b8e7b8e34c01" />

Il vous sera demandé de créer une clée API, pour cela, rendez vous sur l'interface N8N, connectez vous avec les informations configurées précédemment.
En bas à gauche, cliquez sur le profil > "settings":

<img width="1482" height="811" alt="Screenshot 2025-10-30 at 11 30 32" src="https://github.com/user-attachments/assets/2968a3d9-387b-41fa-a56e-9f7b3a0b8701" />
<img width="282" height="114" alt="Screenshot 2025-10-30 at 11 30 37" src="https://github.com/user-attachments/assets/c3f85392-9804-42bc-9bc8-a3d7d69ac603" />

Sur la nouvelle page qui s'ouvre, choisissez "n8n api":

<img width="198" height="445" alt="Screenshot 2025-10-30 at 11 30 43" src="https://github.com/user-attachments/assets/e3151a9b-50b5-46f9-9740-0065cbfb7443" />

Ensuite, cliquer sur "Create an API Key":
<img width="1234" height="405" alt="Screenshot 2025-10-30 at 11 30 47" src="https://github.com/user-attachments/assets/49e8963d-0916-4df1-865f-534c709f7bcc" />

Nommer la clé comme voulu:

<img width="607" height="498" alt="Screenshot 2025-10-30 at 11 30 52" src="https://github.com/user-attachments/assets/ec0b28ae-7218-427b-a6be-c71f862d563b" />

[Etape Importante] Copier la clé API et coller la dans le terminal, une fois le menu fermé, vous ne pourrez plus récupérer la clé API:

<img width="604" height="340" alt="Screenshot 2025-10-30 at 11 30 56" src="https://github.com/user-attachments/assets/e918c349-ba3b-42b2-acf9-f5a1886c2dd9" />
<img width="492" height="74" alt="Screenshot 2025-10-30 at 11 33 16" src="https://github.com/user-attachments/assets/c2700d85-8686-4ac8-b3db-28d25a042b10" />

- Option 2 : Charger un workflow
Une fois la clé précédemment chargée, vous pouvez importer les workflow:
<img width="976" height="432" alt="image" src="https://github.com/user-attachments/assets/9735b721-2b59-4a03-9ecb-91c3a2f73062" />

- Option 3 : Charger une nouvelle clé
  
- Option 4 : Quitter

---

## Enchaînement recommandé

### Étape 1 : Déploiement

Lancer le script de déploiement Azure :
`./deploy_n8n_azure.sh`

Ce script crée la VM et installe n8n.

### Étape 2 : Configuration

Une fois le service n8n accessible, lancer le deuxième script :
`./n8n_manager.sh`


Ce script crée un utilisateur administrateur n8n sécurisé et gère les workflows.

---

## Structure du projet

```sh
/
├── deploy_n8n_azure.sh        # Script 1 : déploie VM Azure et n8n (administrateur)
├── n8n_manager.sh             # Script 2 : configure n8n post-déploiement (étudiants) ├── workflow/                  # Dossier contenant les workflows JSON à importer │
	├── workflow1.json │
	├── workflow2.json │
	└── …
└── ~/.ssh/n8n_azure           # Clés SSH générées par le script 1
```


---

## Prérequis

### Script 1 (deploy_n8n_azure.sh)

- Compte Azure (Azure for Students ou autre)
- Bash (Linux/macOS/WSL)
- Connexion internet

### Script 2 (n8n_manager.sh)

- Bash
- `curl` (installé par défaut)

---

## Résumé des commandes

| Commande | Description |
|----------|-------------|
| `chmod +x deploy_n8n_azure.sh` | Rendre le script de déploiement exécutable |
| `./deploy_n8n_azure.sh` | Lancer la création de la VM Azure + n8n |
| `./deploy_n8n_azure.sh --cleanup` | Supprimer toutes les ressources Azure |
| `./deploy_n8n_azure.sh --cleanup --force` | Supprimer sans confirmation |
| `chmod +x n8n_manager.sh` | Rendre le gestionnaire n8n exécutable |
| `./n8n_manager.sh` | Configurer n8n (utilisateurs, workflows) |

---

## Important - Sécurité

⚠️ **Attention aux points suivants :**

- **Ports ouverts (22/5678)** → À restreindre en production (firewall, NSG)
- **Pas de HTTPS natif** → Ajouter un reverse proxy + certificats SSL en production
- **Clé SSH privée** → Protéger votre machine et ne jamais partager la clé privée
- **Credentials par défaut** → Changer immédiatement le mot de passe `admin123`

---

## Dépannage

### Le service n8n ne démarre pas

Vérifier les logs cloud-init :
`ssh -i ~/.ssh/n8n_azure devopsadmin@ ‘sudo tail -f /var/log/cloud-init-output.log’`


### Impossible de se connecter en SSH

Vérifier que le NSG autorise votre IP :
`az network nsg rule list –resource-group projet-docker-rg –nsg-name projet-docker-nsg01 -o table`

### Erreur lors du chargement de workflow

Vérifier que la clé API est valide et que le fichier JSON est bien formaté :


---

## Licence

Ce projet est fourni à des fins pédagogiques.




