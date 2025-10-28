#!/bin/bash
set -euo pipefail

detect_os() {
  if [ "$(uname)" = "Darwin" ]; then
    echo "macOS"
  elif [ "$(uname -o 2>/dev/null)" = "Msys" ] || [ "$(uname -o 2>/dev/null)" = "Cygwin" ]; then
    echo "Windows"
  elif [ -f /etc/os-release ]; then
    # Extraction de l'ID pour les distributions Linux
    . /etc/os-release
    echo "$ID"
  else
    echo "unknown"
  fi
}

os=$(detect_os)

case "$os" in
  macOS)
    brew update && brew install azure-cli
    ;;
  ubuntu|debian)
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    ;;
  windows)
    # Pour Windows avec Git Bash ou PowerShell. Recommandé : WinGet
    echo "Utilisez la commande suivante dans PowerShell :"
    echo 'winget install -e --id Microsoft.AzureCLI'
    ;;
  *)
    echo "OS non supporté par ce script."
    exit 1
    ;;
esac

# Mise à jour et connexion Azure (valide partout où az est installé)
az upgrade
az login

# =============================================# Configuration# =============================================
BASENAME="projet-docker"
LOCATION="francecentral"
ADMIN_USER="devopsadmin"
VM_SIZE="Standard_B2s"

RG_NAME="${BASENAME}-rg-swe"
VNET_NAME="${BASENAME}-vnet01"
SUBNET_NAME="${BASENAME}-subnet01"
NSG_NAME="${BASENAME}-nsg01"
PUBLIC_IP_NAME="${BASENAME}-ip01"
NIC_NAME="${BASENAME}-nic01"
VM_NAME="${BASENAME}-vm01"

# =============================================# Cloud-init (YAML corrigé avec N8N_SECURE_COOKIE=false)# =============================================
read -r -d '' CLOUD_INIT_YAML << 'EOF' || true
#cloud-config
package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg

groups:
  - docker

system_info:
  default_user:
    groups: [docker]

runcmd:
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - chmod a+r /etc/apt/keyrings/docker.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  - systemctl enable docker
  - systemctl start docker
  - docker run -d --name n8n -p 5678:5678 -e N8N_BASIC_AUTH_ACTIVE=true -e N8N_BASIC_AUTH_USER=admin -e N8N_BASIC_AUTH_PASSWORD=admin123 -e N8N_SECURE_COOKIE=false -v n8n_data:/home/node/.n8n --restart unless-stopped n8nio/n8n
  - sed -i 's/#Port 22/Port 22\nPort 443/' /etc/ssh/sshd_config
  - systemctl restart sshd
EOF

# =============================================# Déploiement Azure# =============================================
echo "==> Using subscription: $(az account show --query name -o tsv)"

echo "==> Creating Resource Group: $RG_NAME ($LOCATION)"
az group create --name "$RG_NAME" --location "$LOCATION" -o none

echo "==> Creating VNet/Subnet"
az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_NAME" \
  --address-prefix 10.0.0.0/16 \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefix 10.0.0.0/24 \
  -o none

echo "==> Creating NSG + rules (22, 443, 5678)"
az network nsg create \
  --resource-group "$RG_NAME" \
  --name "$NSG_NAME" \
  -o none

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

echo "==> Creating Public IP (Standard/Static)"
az network public-ip create \
  --resource-group "$RG_NAME" \
  --name "$PUBLIC_IP_NAME" \
  --sku Standard \
  --allocation-method Static \
  -o none

echo "==> Creating NIC (attach NSG + Public IP)"
az network nic create \
  --resource-group "$RG_NAME" \
  --name "$NIC_NAME" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --public-ip-address "$PUBLIC_IP_NAME" \
  --network-security-group "$NSG_NAME" \
  -o none

echo "==> Preparing cloud-init"
CLOUD_INIT_B64=$(echo "$CLOUD_INIT_YAML" | base64 -w0)

echo "==> Creating VM: $VM_NAME (Debian 11 Gen2)"
az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --nics "$NIC_NAME" \
  --image Debian11 \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --custom-data "$CLOUD_INIT_YAML" \
  -o none

PUBLIC_IP=$(az network public-ip show \
  --resource-group "$RG_NAME" \
  --name "$PUBLIC_IP_NAME" \
  --query ipAddress -o tsv)

echo ""
echo "=========================================="
echo " Déploiement terminé"
echo " RG        : $RG_NAME"
echo " VM        : $VM_NAME ($VM_SIZE)"
echo " Région    : $LOCATION"
echo " Public IP : $PUBLIC_IP"
echo " n8n URL   : http://$PUBLIC_IP:5678"
echo " SSH 22    : ssh $ADMIN_USER@$PUBLIC_IP"
echo " SSH 443   : ssh -p 443 $ADMIN_USER@$PUBLIC_IP"
echo " Auth n8n  : admin / admin123"
echo ""
echo " Attends 3-5 min que cloud-init installe Docker et n8n"
echo " n8n sera accessible directement sans erreur de cookie"
echo "=========================================="
