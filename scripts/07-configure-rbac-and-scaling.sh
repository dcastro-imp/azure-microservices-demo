#!/bin/bash
# RBAC (least privilege per service) + KEDA scale rules (one per subscription
# a worker listens on — see docs/AZURE-LEARNING-GUIDE.md "Proyecto 3c" for why
# a missing scale rule silently prevents scale-out even if the code is fine).
set -e
source "$(dirname "$0")/00-vars.sh"

assign_role() {
  local APP=$1
  local ROLE=$2
  local ID=$(az containerapp show --name $APP --resource-group $RG --query identity.principalId -o tsv)
  az role assignment create --assignee $ID --role "$ROLE" --scope $SB_SCOPE
}

# productsapi: sends to both topics, plus reads Service Bus admin info for /api/status
# (Data Owner is broader than strictly needed — a deliberate, documented trade-off).
assign_role productsapi "Azure Service Bus Data Owner"

# inventory-worker and shipping-worker both send AND receive (they publish
# follow-up events), so they need Owner too.
assign_role inventory-worker "Azure Service Bus Data Owner"
assign_role shipping-worker "Azure Service Bus Data Owner"

# notification-worker and audit-worker only ever receive.
assign_role notification-worker "Azure Service Bus Data Receiver"
assign_role audit-worker "Azure Service Bus Data Receiver"

# KEDA needs its own connection string secret (separate from the app's own
# AAD-based ServiceBusClient) to query queue/topic depth for scaling decisions.
SB_KEY=$(az servicebus namespace authorization-rule keys list --resource-group $RG \
  --namespace-name $SB_NAMESPACE --name RootManageSharedAccessKey --query primaryConnectionString -o tsv)

add_scale_rule() {
  local APP=$1
  local RULE_NAME=$2
  local TOPIC=$3
  local SUB=$4
  az containerapp secret set --name $APP --resource-group $RG --secrets "servicebus-conn=$SB_KEY"
  az containerapp update --name $APP --resource-group $RG \
    --scale-rule-name $RULE_NAME --scale-rule-type azure-servicebus \
    --scale-rule-metadata "topicName=$TOPIC" "subscriptionName=$SUB" "namespace=$SB_NAMESPACE" "messageCount=5" \
    --scale-rule-auth "connection=servicebus-conn"
}

add_scale_rule inventory-worker     products-scaler products inventory-sub
add_scale_rule inventory-worker     orders-scaler   orders   order-created-sub
add_scale_rule shipping-worker      orders-scaler   orders   stock-reserved-sub
add_scale_rule notification-worker  products-scaler products notification-sub
add_scale_rule notification-worker  orders-scaler   orders   order-status-sub
add_scale_rule audit-worker         orders-scaler   orders   audit-sub

echo "=== RBAC y KEDA scale rules configurados ==="
