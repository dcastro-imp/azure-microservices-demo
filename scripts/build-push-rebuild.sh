#!/bin/bash
set -e
ACR=acrproductsdennis.azurecr.io
ROOT="/home/dennis/CascadeProjects/azure-microservices-demo"

for pair in "ProductsApi:productsapi" "InventoryWorker:inventoryworker" "ShippingWorker:shippingworker" "NotificationWorker:notificationworker" "AuditWorker:auditworker"; do
  SRC="${pair%%:*}"
  IMG="${pair##*:}"
  echo "=== $SRC -> $ACR/$IMG:latest ==="
  docker build -t $ACR/$IMG:latest "$ROOT/src/$SRC"
  docker push $ACR/$IMG:latest
done

echo "=== frontend -> $ACR/frontend:latest ==="
docker build --build-arg VITE_API_URL=https://productsapi.blacksmoke-a2581388.centralus.azurecontainerapps.io \
  -t $ACR/frontend:latest "$ROOT/src/frontend"
docker push $ACR/frontend:latest

echo "=== Listo ==="
