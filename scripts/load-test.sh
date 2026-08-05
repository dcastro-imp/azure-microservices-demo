#!/bin/bash
# Simple load generator: fires N POST requests against ProductsApi to pile up
# messages in the Service Bus topic and trigger KEDA scale-out on the workers.
source "$(dirname "$0")/00-vars.sh"

FQDN=$(az containerapp show --name productsapi --resource-group $RG --query properties.configuration.ingress.fqdn -o tsv)
URL="https://$FQDN/api/products"
COUNT=${1:-30}

for i in $(seq 1 "$COUNT"); do
  curl -s -o /dev/null -X POST "$URL" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"LoadTest-$i\",\"category\":\"Test\",\"price\":1,\"stock\":1}" &
done
wait
echo "Disparados $COUNT requests."
