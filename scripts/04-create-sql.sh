#!/bin/bash
# Azure SQL Server + Database, plus a Private Endpoint into data-subnet so
# the database has NO public network access. Public access is toggled on
# temporarily only for the one-time schema setup (scripts/sql/*.sql) via the
# portal Query Editor, then switched off again — see
# docs/AZURE-LEARNING-GUIDE.md "Proyecto 3b" for why this is a dev-only
# shortcut (real production access uses VPN/Bastion instead).
set -e
source "$(dirname "$0")/00-vars.sh"

echo "=== SQL Server (Azure AD-only auth) ==="
read -p "Tu email de Azure AD (admin de la base): " ADMIN_EMAIL
ADMIN_SID=$(az ad signed-in-user show --query id -o tsv)

az sql server create --resource-group $RG --name $SQL_SERVER --location $LOCATION \
  --enable-ad-only-auth --external-admin-principal-type User \
  --external-admin-name "$ADMIN_EMAIL" --external-admin-sid $ADMIN_SID

az sql db create --resource-group $RG --server $SQL_SERVER --name $SQL_DB \
  --edition GeneralPurpose --family Gen5 --capacity 1 \
  --compute-model Serverless --auto-pause-delay 60 --min-capacity 0.5

echo "=== Private DNS Zone + vinculo a la VNet ==="
az network private-dns zone create --resource-group $RG --name privatelink.database.windows.net
az network private-dns link vnet create --resource-group $RG \
  --zone-name privatelink.database.windows.net --name dns-link-microservices \
  --virtual-network $VNET_NAME --registration-enabled false

echo "=== Private Endpoint en data-subnet ==="
SQL_ID=$(az sql server show --resource-group $RG --name $SQL_SERVER --query id -o tsv)
az network private-endpoint create --resource-group $RG --name pe-sql-microservices \
  --vnet-name $VNET_NAME --subnet $DATA_SUBNET \
  --private-connection-resource-id $SQL_ID --group-id sqlServer --connection-name pe-sql-connection

az network private-endpoint dns-zone-group create --resource-group $RG \
  --endpoint-name pe-sql-microservices --name sql-dns-zone-group \
  --private-dns-zone privatelink.database.windows.net --zone-name sql

echo "=== SQL creado. Pendiente (manual, una sola vez): ==="
echo "1. az sql server update --resource-group $RG --name $SQL_SERVER --set publicNetworkAccess=Enabled"
echo "2. Correr scripts/sql/01-schema.sql y scripts/sql/02-grant-managed-identities.sql en el Query Editor del portal"
echo "3. az sql server update --resource-group $RG --name $SQL_SERVER --set publicNetworkAccess=Disabled"
