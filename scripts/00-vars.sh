#!/bin/bash
# Shared variables sourced by every script in this folder.
# Adjust these if you're deploying to a different subscription/naming scheme.

export RG=rg-microservices
export LOCATION=centralus
export ACR_NAME=acrproductsdennis
export ACR=$ACR_NAME.azurecr.io
export VNET_NAME=vnet-microservices
export INFRA_SUBNET=infra-subnet
export DATA_SUBNET=data-subnet
export NSG_NAME=nsg-infra-subnet
export CAE_NAME=cae-microservices-vnet
export SB_NAMESPACE=sb-microservices-dennis
export SB_FQDN=$SB_NAMESPACE.servicebus.windows.net
export SQL_SERVER=sql-microservices-dennis
export SQL_DB=microservicesdb
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export SB_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.ServiceBus/namespaces/$SB_NAMESPACE"
export SQL_CONN="Server=tcp:$SQL_SERVER.database.windows.net,1433;Database=$SQL_DB;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;"
