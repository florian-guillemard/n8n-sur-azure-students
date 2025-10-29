#!/bin/bash
set -euo pipefail

# ============================================= Configuration =============================================
BASENAME="projet-docker"
ADMIN_USER="devopsadmin"
VM_SIZE="Standard_B2s"

RG_NAME="${BASENAME}-rg"
VNET_NAME="${BASENAME}-vnet01"
SUBNET_NAME="${BASENAME}-subnet01"
NSG_NAME="${BASENAME}-nsg01"
PUBLIC_IP_NAME="${BASENAME}-ip01"
NIC_NAME="${BASENAME}-nic01"
VM_NAME="${BASENAME}-vm01"

# ============================================= Fonction de nettoyage =============================================
cleanup_resources() {
  echo ""
  echo "=========================================="
  echo "⚠️  SUPPRESSION DES RESSOURCES"
  echo "=========================================="
  echo ""
  
  # Vérifier si le RG existe
  if ! az group show --name "$RG_NAME" --output none 2>/dev/null; then
    echo "❌ Le Resource Group '$RG_NAME' n'existe pas ou a déjà été supprimé"
    exit 0
  fi
  
  echo "Cette action va supprimer :"
  echo "  • Resource Group : $RG_NAME"
  echo "  • VM et tous ses disques"
  echo "  • Réseau (VNet, Subnet, NSG, NIC)"
  echo "  • IP publique"
  echo "  • Toutes les ressources associées"
  echo ""
  
  # Afficher les ressources existantes
  echo "Ressources actuelles :"
  az resource list --resource-group "$RG_NAME" --query "[].{Nom:name, Type:type}" -o table
  
  echo ""
  echo "⏱ Temps estimé : 10-20 minutes"
  echo ""
  read -p "Êtes-vous sûr de vouloir tout supprimer ? (oui/non) : " confirm
  
  if [ "$confirm" = "oui" ] || [ "$confirm" = "OUI" ]; then
    echo ""
    echo "==> Suppression du Resource Group en cours..."
    az group delete --name "$RG_NAME" --yes --no-wait
    echo "✓ Suppression lancée en arrière-plan"
    echo ""
    echo "Pour suivre la progression :"
    echo "  az group show --name $RG_NAME --query \"properties.provisioningState\" -o tsv"
    echo "  # Retournera une erreur quand supprimé complètement"
    echo ""
  else
    echo "❌ Suppression annulée"
    echo ""
  fi
  
  exit 0
}

# ============================================= Mode Nettoyage =============================================
# Si --cleanup est passé, exécuter nettoyage et sortir
if [ "${1:-}" = "--cleanup" ]; then
  cleanup_resources
fi

# ============================================= Détection OS =============================================
detect_os() {
  if [ "$(uname)" = "Darwin" ]; then
    echo "macOS"
  elif [ "$(uname -o 2>/dev/null)" = "Msys" ] || [ "$(uname -o 2>/dev/null)" = "Cygwin" ]; then
    echo "Windows"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu) echo "ubuntu" ;;
      debian) echo "debian" ;;
      fedora) echo "fedora" ;;
      centos) echo "centos" ;;
      arch) echo "arch" ;;
      *) echo "unsupported" ;;
    esac
  else
    echo "unsupported"
  fi
}

os=$(detect_os)

if [ "$os" = "unsupported" ]; then
  echo "ERREUR : Votre OS n'est pas inclus dans les distributions prises en charge."
  echo "Merci de voir avec le professeur pour une assistance adaptée."
  exit 1
fi

case "$os" in
  macOS)
    if ! command -v az &> /dev/null; then
      echo "Installation Azure CLI sur macOS..."
      brew update && brew install azure-cli
    fi
    ;;
  ubuntu|debian)
    if ! command -v az &> /dev/null; then
      echo "Installation Azure CLI sur $os..."
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi
    ;;
  fedora|centos|arch)
    if ! command -v az &> /dev/null; then
      echo "Installation Azure CLI sur $os..."
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi
    ;;
  Windows)
    echo "Utilisez la commande suivante dans PowerShell :"
    echo 'winget install -e --id Microsoft.AzureCLI'
    exit 0
    ;;
esac

# ============================================= Connexion Azure =============================================
echo "==> Mise à jour Azure CLI..."
az upgrade --yes 2>/dev/null || true

az login

# Récupération de l'ID de subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# ============================================= Sélection Région =============================================
echo ""
echo "==> Vérification des régions autorisées..."
# Récupération des régions depuis la policy (portable toutes versions)
ALLOWED_REGIONS=$(az policy assignment list \
  --query "[?displayName=='Allowed resource deployment regions'].parameters.listOfAllowedLocations.value[]" \
  -o tsv 2>/dev/null || echo "")

# Conversion en array PORTABLE
POLICY_REGIONS=()
if [ -n "$ALLOWED_REGIONS" ]; then
  while IFS=$'\n' read -r line; do
    [ -n "$line" ] && POLICY_REGIONS+=("$line")
  done <<< "$ALLOWED_REGIONS"
fi

# Arrêt si aucune région récupérée dynamiquement
if [ ${#POLICY_REGIONS[@]} -eq 0 ]; then
  echo "ERREUR : Impossible de récupérer les régions autorisées depuis Azure Policy"
  echo "  Vérifiez vos permissions et la présence d'une policy de localisation"
  exit 1
fi

echo "Régions autorisées par Azure :"
printf '  ✓ %s\n' "${POLICY_REGIONS[@]}"

# Sélection de la première région disponible (100% dynamique)
if [ ${#POLICY_REGIONS[@]} -gt 0 ]; then
  LOCATION="${POLICY_REGIONS[0]}"
  echo ""
  echo "Région sélectionnée automatiquement : $LOCATION"
else
  echo "ERREUR : Aucune région valide trouvée."
  exit 1
fi

DISK_SKU="Standard_LRS"

echo ""
echo "=========================================="
echo "Configuration de déploiement :"
echo "  Région      : $LOCATION"
echo "  Stockage    : $DISK_SKU"
echo "  Abonnement  : $(az account show --query name -o tsv)"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "=========================================="
echo ""
echo "⏱ Pause 5 secondes avant déploiement..."
sleep 5

# ============================================= Resource Group =============================================
echo "==> Vérification du groupe de ressources : $RG_NAME"

if az group show --name "$RG_NAME" --output none 2>/dev/null; then
  EXISTING_LOC=$(az group show --name "$RG_NAME" --query location -o tsv)
  echo "✓ RG existant trouvé en région : $EXISTING_LOC"
  
  if [ "$EXISTING_LOC" != "$LOCATION" ]; then
    echo "❌ Conflit de région détecté ! Suppression du RG..."
    az group delete --name "$RG_NAME" --yes --no-wait
    echo "⏱ Attente 60s pour suppression complète..."
    sleep 60
    
    echo "==> Création du groupe de ressources : $RG_NAME ($LOCATION)"
    az group create --name "$RG_NAME" --location "$LOCATION" --output none
  else
    echo "✓ RG en bonne région, on continue"
  fi
else
  echo "==> Création du groupe de ressources : $RG_NAME ($LOCATION)"
  az group create --name "$RG_NAME" --location "$LOCATION" --output none
fi

echo "✓ Resource Group prêt"
CLOUD_INIT_YAML=$(cat << 'CLOUDEOF'
#cloud-config
package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg

write_files:
  - path: /tmp/setup-docker.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -euxo pipefail
      exec > /tmp/docker-install.log 2>&1
      
      echo "Starting Docker installation..."
      
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod a+r /etc/apt/keyrings/docker.gpg
      
      echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" > /etc/apt/sources.list.d/docker.list
      
      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      
      systemctl enable docker
      systemctl start docker
      
      usermod -aG docker devopsadmin
      
      sleep 5
      
      docker run -d --name n8n -p 5678:5678 \
        -e N8N_BASIC_AUTH_ACTIVE=true \
        -e N8N_BASIC_AUTH_USER=admin \
        -e N8N_BASIC_AUTH_PASSWORD=admin123 \
        -e N8N_SECURE_COOKIE=false \
        -v n8n_/home/node/.n8n \
        --restart unless-stopped \
        n8nio/n8n

      echo "Installation completed successfully"

runcmd:
  - /tmp/setup-docker.sh
  - sed -i 's/#Port 22/Port 22\nPort 443/' /etc/ssh/sshd_config
  - systemctl restart sshd

CLOUDEOF
)
# ============================================= Réseau Azure =============================================
echo ""
echo "==> Création VNet/Subnet"
az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_NAME" \
  --location "$LOCATION" \
  --address-prefix 10.0.0.0/16 \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefix 10.0.0.0/24 \
  -o none

echo "==> Création NSG"
az network nsg create \
  --resource-group "$RG_NAME" \
  --name "$NSG_NAME" \
  --location "$LOCATION" \
  -o none

echo "==> Création règles NSG (SSH 22+443, n8n 5678)"
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name "$NSG_NAME" \
  --name AllowSSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 443 \
  --protocol Tcp \
  --access Allow \
  -o none

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name "$NSG_NAME" \
  --name AllowN8N \
  --priority 1010 \
  --source-address-prefixes '*' \
  --destination-port-ranges 5678 \
  --protocol Tcp \
  --access Allow \
  -o none

echo "==> Création IP publique (Standard/Statique)"
az network public-ip create \
  --resource-group "$RG_NAME" \
  --name "$PUBLIC_IP_NAME" \
  --location "$LOCATION" \
  --sku Standard \
  --allocation-method Static \
  -o none

echo "==> Création NIC (attachement NSG + IP publique)"
az network nic create \
  --resource-group "$RG_NAME" \
  --name "$NIC_NAME" \
  --location "$LOCATION" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --public-ip-address "$PUBLIC_IP_NAME" \
  --network-security-group "$NSG_NAME" \
  -o none

# ============================================= Machine Virtuelle =============================================
echo ""
echo "==> Création VM : $VM_NAME (Debian 11 Gen2)"
az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --location "$LOCATION" \
  --nics "$NIC_NAME" \
  --image Debian11 \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --storage-sku "$DISK_SKU" \
  --custom-data <(echo "$CLOUD_INIT_YAML") \
  -o none

PUBLIC_IP=$(az network public-ip show \
  --resource-group "$RG_NAME" \
  --name "$PUBLIC_IP_NAME" \
  --query ipAddress -o tsv)

# ============================================= Résumé =============================================
echo ""
echo "=========================================="
echo "✅ Déploiement terminé avec succès !"
echo "=========================================="
echo ""
echo "📦 Ressources créées :"
echo "  Resource Group : $RG_NAME"
echo "  VM             : $VM_NAME ($VM_SIZE)"
echo "  Région         : $LOCATION"
echo "  IP Publique    : $PUBLIC_IP"
echo ""
echo "🔗 Accès :"
echo "  n8n Interface  : http://$PUBLIC_IP:5678"
echo "  SSH (port 22)  : ssh $ADMIN_USER@$PUBLIC_IP"
echo "  SSH (port 443) : ssh -p 443 $ADMIN_USER@$PUBLIC_IP"
echo ""
echo "🔐 Credentials n8n :"
echo "  Username       : admin"
echo "  Password       : admin123"
echo ""
echo "⏱ Installation en cours :"
echo "  Attends 3-5 minutes que cloud-init installe Docker et n8n"
echo "  Suivi des logs : ssh $ADMIN_USER@$PUBLIC_IP 'sudo tail -f /var/log/cloud-init-output.log'"
echo ""
echo "🔒 Sécurité :"
echo "  ⚠ NSG ouvert à tous (*) - À restreindre en production !"
echo "  ⚠ Credentials en clair - À changer immédiatement !"
echo "  ⚠ Pas de HTTPS - À configurer avec reverse proxy + Let's Encrypt"
echo ""
echo "🗑️  Nettoyage :"
echo "  Pour supprimer toutes les ressources :"
echo "    $0 --cleanup"
echo ""
echo "=========================================="
