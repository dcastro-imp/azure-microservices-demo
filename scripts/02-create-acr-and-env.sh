#!/bin/bash
# Azure Container Registry + the Container Apps Environment, integrated into
# the VNet's infra-subnet created in 01-create-network.sh.
set -e
source "$(dirname "$0")/00-vars.sh"

az acr create --resource-group $RG --name $ACR_NAME --sku Basic

SUBNET_ID=$(az network vnet subnet show --resource-group $RG --vnet-name $VNET_NAME --name $INFRA_SUBNET --query id -o tsv)
az containerapp env create --name $CAE_NAME --resource-group $RG --location $LOCATION \
  --infrastructure-subnet-resource-id $SUBNET_ID

echo "=== ACR y Container Apps Environment creados ==="
