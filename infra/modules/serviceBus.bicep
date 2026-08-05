// One Service Bus namespace, two topics:
//   - "products": plain fan-out demo (no filters)
//   - "orders": the real pipeline, one topic + 4 event types routed via SQL
//     Filters per subscription. See docs/AZURE-LEARNING-GUIDE.md "Proyecto 3c".

param location string
param namespaceName string

resource sbNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Standard'
  }
}

resource productsTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  parent: sbNamespace
  name: 'products'
}

resource inventorySub 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: productsTopic
  name: 'inventory-sub'
}

resource notificationSub 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: productsTopic
  name: 'notification-sub'
}

resource ordersTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  parent: sbNamespace
  name: 'orders'
}

resource orderCreatedSub 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: ordersTopic
  name: 'order-created-sub'
}
resource orderCreatedFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2024-01-01' = {
  parent: orderCreatedSub
  name: 'OrderCreatedFilter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'sys.Label = \'OrderCreated\''
    }
  }
}

resource stockReservedSub 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: ordersTopic
  name: 'stock-reserved-sub'
}
resource stockReservedFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2024-01-01' = {
  parent: stockReservedSub
  name: 'StockReservedFilter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'sys.Label = \'StockReserved\''
    }
  }
}

resource orderStatusSub 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: ordersTopic
  name: 'order-status-sub'
}
resource orderStatusFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2024-01-01' = {
  parent: orderStatusSub
  name: 'OrderStatusFilter'
  properties: {
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'sys.Label IN (\'StockReservationFailed\',\'ShippingScheduled\')'
    }
  }
}

// No filter resource here on purpose: audit-sub keeps the default TrueFilter,
// receiving a copy of every event published to the topic.
resource auditSub 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: ordersTopic
  name: 'audit-sub'
}

output namespaceId string = sbNamespace.id
output namespaceName string = sbNamespace.name
output namespaceFqdn string = '${sbNamespace.name}.servicebus.windows.net'
