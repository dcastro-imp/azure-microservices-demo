#!/bin/bash
# Service Bus namespace with 2 topics:
#   - "products": simple pub/sub demo (ProductCreated -> 2 subscribers, no filters)
#   - "orders": the real order pipeline, one topic with 4 event types routed
#     via SQL Filters on each subscription. See docs/AZURE-LEARNING-GUIDE.md
#     "Proyecto 3c" for why one topic + filters instead of one topic per event.
set -e
source "$(dirname "$0")/00-vars.sh"

az servicebus namespace create --resource-group $RG --name $SB_NAMESPACE --sku Standard --location $LOCATION

# --- Topic: products (no filters, plain fan-out) ---
az servicebus topic create --resource-group $RG --namespace-name $SB_NAMESPACE --name products
az servicebus topic subscription create --resource-group $RG --namespace-name $SB_NAMESPACE --topic-name products --name inventory-sub
az servicebus topic subscription create --resource-group $RG --namespace-name $SB_NAMESPACE --topic-name products --name notification-sub

# --- Topic: orders (filtered subscriptions) ---
az servicebus topic create --resource-group $RG --namespace-name $SB_NAMESPACE --name orders

create_filtered_sub() {
  local SUB=$1
  local FILTER_NAME=$2
  local FILTER_EXPR=$3
  az servicebus topic subscription create --resource-group $RG --namespace-name $SB_NAMESPACE --topic-name orders --name $SUB
  az servicebus topic subscription rule create --resource-group $RG --namespace-name $SB_NAMESPACE --topic-name orders \
    --subscription-name $SUB --name $FILTER_NAME --filter-sql-expression "$FILTER_EXPR"
  # The default rule matches everything (TrueFilter) — remove it so only our filter applies.
  az servicebus topic subscription rule delete --resource-group $RG --namespace-name $SB_NAMESPACE --topic-name orders \
    --subscription-name $SUB --name '$Default' || true
}

create_filtered_sub order-created-sub  OrderCreatedFilter  "sys.Label = 'OrderCreated'"
create_filtered_sub stock-reserved-sub StockReservedFilter "sys.Label = 'StockReserved'"
create_filtered_sub order-status-sub   OrderStatusFilter   "sys.Label IN ('StockReservationFailed','ShippingScheduled')"

# audit-sub intentionally has NO filter — it receives a copy of every event,
# which is what makes a full audit trail per order possible.
az servicebus topic subscription create --resource-group $RG --namespace-name $SB_NAMESPACE --topic-name orders --name audit-sub

echo "=== Service Bus (namespace, topics, subscriptions, filtros) creado ==="
