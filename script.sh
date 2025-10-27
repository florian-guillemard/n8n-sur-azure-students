brew update && brew install azure-cli
az upgrade
az login

export RANDOM_ID="$(openssl rand -hex 3)"
export MY_RESOURCE_GROUP_NAME="myVMResourceGroup$RANDOM_ID"
export REGION=francecentral

az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

export MY_VM_NAME="myVM$RANDOM_ID"
export MY_USERNAME=azureuser


az vm create \
  --resource-group $MY_RESOURCE_GROUP_NAME \
  --name myVM$RANDOM_ID \
  --image Debian11 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys

export IP_ADDRESS=$(az vm show --show-details --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --query publicIps --output tsv)
ssh -o StrictHostKeyChecking=no $MY_USERNAME@$IP_ADDRESS
