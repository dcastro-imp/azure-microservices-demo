#!/bin/bash
# Deploys all 5 backend Container Apps + the frontend. Run this AFTER
# scripts/05-build-and-push-images.sh (images must already exist in ACR) and
# AFTER the SQL setup (scripts/04-create-sql.sh + scripts/sql/*.sql), since
# workers reference a "sql-conn" secret from the start.
set -e
source "$(dirname "$0")/00-vars.sh"

# --- productsapi (external ingress, the only one the internet can reach directly) ---
az containerapp create --name productsapi --resource-group $RG --environment $CAE_NAME \
  --image $ACR/productsapi:latest --target-port 8080 --ingress external \
  --registry-server $ACR --registry-identity system \
  --env-vars ServiceBusNamespace=$SB_FQDN
az containerapp secret set --name productsapi --resource-group $RG --secrets "sql-conn=$SQL_CONN"
az containerapp update --name productsapi --resource-group $RG \
  --set-env-vars ServiceBusNamespace=$SB_FQDN UseSqlServer=true "ConnectionStrings__Default=secretref:sql-conn"

PRODUCTSAPI_FQDN=$(az containerapp show --name productsapi --resource-group $RG --query properties.configuration.ingress.fqdn -o tsv)
echo "productsapi disponible en: https://$PRODUCTSAPI_FQDN"

# --- inventory-worker (2 processors: products/inventory-sub + orders/order-created-sub) ---
az containerapp create --name inventory-worker --resource-group $RG --environment $CAE_NAME \
  --image $ACR/inventoryworker:latest --registry-server $ACR --registry-identity system \
  --min-replicas 0 --max-replicas 3 --env-vars ServiceBusNamespace=$SB_FQDN
az containerapp secret set --name inventory-worker --resource-group $RG --secrets "sql-conn=$SQL_CONN"
az containerapp update --name inventory-worker --resource-group $RG \
  --set-env-vars "ConnectionStrings__Default=secretref:sql-conn"

# --- shipping-worker (orders/stock-reserved-sub) ---
az containerapp create --name shipping-worker --resource-group $RG --environment $CAE_NAME \
  --image $ACR/shippingworker:latest --registry-server $ACR --registry-identity system \
  --min-replicas 0 --max-replicas 3 --env-vars ServiceBusNamespace=$SB_FQDN
az containerapp secret set --name shipping-worker --resource-group $RG --secrets "sql-conn=$SQL_CONN"
az containerapp update --name shipping-worker --resource-group $RG \
  --set-env-vars "ConnectionStrings__Default=secretref:sql-conn"

# --- notification-worker (2 processors: products/notification-sub + orders/order-status-sub; no DB access) ---
az containerapp create --name notification-worker --resource-group $RG --environment $CAE_NAME \
  --image $ACR/notificationworker:latest --registry-server $ACR --registry-identity system \
  --min-replicas 0 --max-replicas 2 --env-vars ServiceBusNamespace=$SB_FQDN

# --- audit-worker (orders/audit-sub, no filter) ---
az containerapp create --name audit-worker --resource-group $RG --environment $CAE_NAME \
  --image $ACR/auditworker:latest --registry-server $ACR --registry-identity system \
  --min-replicas 0 --max-replicas 2 --env-vars ServiceBusNamespace=$SB_FQDN
az containerapp secret set --name audit-worker --resource-group $RG --secrets "sql-conn=$SQL_CONN"
az containerapp update --name audit-worker --resource-group $RG \
  --set-env-vars "ConnectionStrings__Default=secretref:sql-conn"

# --- frontend: needs productsapi's FQDN baked in at build time, so it's built here, not in step 05 ---
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
docker build --build-arg VITE_API_URL=https://$PRODUCTSAPI_FQDN -t $ACR/frontend:latest "$ROOT/src/frontend"
docker push $ACR/frontend:latest
az containerapp create --name frontend --resource-group $RG --environment $CAE_NAME \
  --image $ACR/frontend:latest --target-port 80 --ingress external \
  --registry-server $ACR --registry-identity system

echo "=== Todas las Container Apps desplegadas ==="
echo "Siguiente paso: scripts/07-configure-rbac-and-scaling.sh"
