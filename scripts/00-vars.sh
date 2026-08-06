#!/bin/bash
# Shared variables sourced by every script in this folder.
#
# Portable by design: ACR, SQL Server, and Service Bus namespace names must
# be GLOBALLY UNIQUE across all of Azure — so instead of hardcoding a name
# tied to one person's account, this generates (and caches) a random suffix
# on first run, stored in .suffix (gitignored, never committed). Anyone who
# clones this repo and runs these scripts gets their own unique names
# automatically, with zero manual editing required.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUFFIX_FILE="$SCRIPT_DIR/.suffix"

if [ ! -f "$SUFFIX_FILE" ]; then
  # 6 lowercase alphanumeric chars — short enough to stay under Azure's
  # per-resource-type name length limits (e.g. Storage Accounts cap at 24).
  head -c 100 /dev/urandom | tr -dc 'a-z0-9' | head -c 6 > "$SUFFIX_FILE"
fi
SUFFIX=$(cat "$SUFFIX_FILE")

export RG=rg-microservices
export LOCATION=centralus
export ACR_NAME=acrmicro$SUFFIX
export ACR=$ACR_NAME.azurecr.io
export VNET_NAME=vnet-microservices
export INFRA_SUBNET=infra-subnet
export DATA_SUBNET=data-subnet
export NSG_NAME=nsg-infra-subnet
export CAE_NAME=cae-microservices-vnet
export SB_NAMESPACE=sb-microservices-$SUFFIX
export SB_FQDN=$SB_NAMESPACE.servicebus.windows.net
export SQL_SERVER=sql-microservices-$SUFFIX
export SQL_DB=microservicesdb
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export SB_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.ServiceBus/namespaces/$SB_NAMESPACE"
export SQL_CONN="Server=tcp:$SQL_SERVER.database.windows.net,1433;Database=$SQL_DB;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;"

echo "Usando sufijo unico: $SUFFIX (guardado en scripts/.suffix — no lo borres entre corridas de los mismos scripts)"
