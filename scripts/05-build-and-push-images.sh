#!/bin/bash
# Builds and pushes all 6 images to ACR. Run "az acr login --name $ACR_NAME"
# first if your Docker session has expired (tokens last a few hours).
set -e
source "$(dirname "$0")/00-vars.sh"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for SERVICE in ProductsApi InventoryWorker ShippingWorker NotificationWorker AuditWorker; do
  IMAGE=$(echo $SERVICE | tr '[:upper:]' '[:lower:]')
  echo "=== Building $SERVICE -> $ACR/$IMAGE:latest ==="
  docker build -t $ACR/$IMAGE:latest "$ROOT/src/$SERVICE"
  docker push $ACR/$IMAGE:latest
done

echo "=== Building frontend -> $ACR/frontend:latest ==="
docker build --build-arg VITE_API_URL=https://productsapi.<REEMPLAZAR-CON-TU-DOMINIO> \
  -t $ACR/frontend:latest "$ROOT/src/frontend"
docker push $ACR/frontend:latest

echo "=== Listo ==="
