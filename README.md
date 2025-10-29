README — Automatisation complète du déploiement et configuration de n8n sur Azure

Ce projet contient 2 scripts Bash distincts, complémentaires, accompagnant un déploiement automatisé d’un serveur n8n sur une machine virtuelle Azure, suivi d’une configuration simple via l’interface n8n.

Script 1 – Déploiement Azure automatisé ( deploy_n8n_azure.sh )
Fonctionnalités principales
	•	Vérifie et installe Azure CLI si nécessaire.
	•	Authentifie l’utilisateur sur Azure.
	•	Récupère la liste des régions autorisées via la politique Azure.
	•	Crée les ressources Azure nécessaires (Resource Group, réseau virtuel, sous-réseau, groupes de sécurité).
	•	Configure les règles du groupe de sécurité pour ouvrir SSH (ports 22 et 443) et le port 5678 de n8n.
	•	Génère une paire de clés SSH locale pour la VM ( ~/.ssh/n8n_azure ).
	•	Crée une machine virtuelle Debian 11 avec cloud-init :
	•	Installe Docker.
	•	Lance automatiquement un conteneur n8n avec authentification basique (admin/admin123).
	•	Attend que le service n8n soit disponible sur le port 5678 de la VM.
	•	Affiche les informations d’accès (IP publique, SSH, credentials par défaut).

Comment utiliser
	1.	Rendre le script exécutable :
  `chmod +x deploy_n8n_azure.sh`
  2. Lancer le script 
  `./deploy_n8n_azure.sh`
  3.	Se connecter à Azure via l’interface ouverte dans le navigateur pour autoriser le script.
	4.	Le script s’occupe de tout le déploiement.
	5.	À la fin, il affiche :
	•	L’adresse IP publique de la machine.
	•	Les accès SSH.
	•	L’URL n8n (ex:  http://<IP>:5678 ).

Nettoyage:
	•	Pour supprimer toutes les ressources Azure et les clés SSH associées, lancer :
  `./deploy_n8n_azure.sh --cleanup`

Script 2 – Gestion simple de n8n ( n8n_manager.sh )
Objectif
Après que la VM et n8n soient déployés, ce script sert à configurer proprement n8n sans intervention manuelle lourde.
Il permet de :
	•	Créer un utilisateur administrateur n8n (en demandant IP, email, prénom, nom, mot de passe sécurisé).
	•	Enregistrer et réutiliser la clé API automatiquement.
	•	Charger des workflows JSON dans n8n via API.
	•	Mettre à jour ou supprimer la clé API.
Utilisation
	1.	Copier et rendre exécutable :
  `chmod +x n8n_manager.sh`
  2. Lancer le script :
  `./n8n_manager.sh`
  3.	Suivre le menu interactif simple (création utilisateur, import workflow, gestion clé API).

Enchaînement recommandé
•	D’abord, lancer le script de déploiement Azure :  ./deploy_n8n_azure.sh  pour créer la VM et installer n8n.
•	Une fois le service n8n accessible, lancer le deuxième script :  ./n8n_manager.sh  qui va créer un utilisateur administrateur n8n sécurisé et gérer les workflows.

Structure du projet
/
├── deploy_n8n_azure.sh        # Script 1 : déploie VM Azure et n8n (administrateur)
├── n8n_manager.sh             # Script 2 : configure n8n post-déploiement (étudiants)
├── workflow/                  # Dossier contenant les workflows JSON à importer
│   ├── workflow1.json
│   ├── workflow2.json
│   └── ...
└── ~/.ssh/n8n_azure           # Clés SSH générées par le script 1


Important
	•	Ports ouverts (22/443/5678) → À restreindre en production (firewall, NSG).
	•	Pas de HTTPS natif dans ce déploiement → Ajouter un reverse proxy + certifiats SSL en production.
	•	Clé SSH privée générée localement → Protéger votre machine.


