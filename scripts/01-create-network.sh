#!/bin/bash
# Creates the VNet + 2 subnets (one for Container Apps, one for data/Private
# Endpoints) + NSG. See docs/AZURE-LEARNING-GUIDE.md "Proyecto 3b" for the
# concepts (CIDR notation, subnet delegation, default NSG rules).
set -e
source "$(dirname "$0")/00-vars.sh"

az group create --name $RG --location $LOCATION

az network vnet create --resource-group $RG --name $VNET_NAME \
  --address-prefix 10.0.0.0/16 --subnet-name $INFRA_SUBNET --subnet-prefix 10.0.0.0/23

az network vnet subnet create --resource-group $RG --vnet-name $VNET_NAME \
  --name $DATA_SUBNET --address-prefix 10.0.2.0/24

# Container Apps environments with VNet integration require the infra subnet
# to be delegated to Microsoft.App/environments.
az network vnet subnet update --resource-group $RG --vnet-name $VNET_NAME \
  --name $INFRA_SUBNET --delegations Microsoft.App/environments

az network nsg create --resource-group $RG --name $NSG_NAME
az network vnet subnet update --resource-group $RG --vnet-name $VNET_NAME \
  --name $INFRA_SUBNET --network-security-group $NSG_NAME

echo "=== Red creada ==="
