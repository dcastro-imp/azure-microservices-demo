// Orchestrates the full microservices architecture: VNet, ACR, Container
// Apps Environment, Service Bus (2 topics, 5 filtered subscriptions), SQL
// (Private Endpoint, no public access), and 6 Container Apps.
//
// KNOWN GAP (documented on purpose, see infra/README.md): this template does
// NOT run the SQL `CREATE USER FROM EXTERNAL PROVIDER` statements — that's
// T-SQL, not an ARM resource. Run scripts/sql/*.sql manually after this
// deploys (with public network access temporarily enabled), same as the
// imperative scripts/ flow.
//
// Also NOT automated here: baking the frontend's VITE_API_URL at Docker
// build time (it needs productsapi's FQDN, which only exists after this
// deploys) and pushing images to ACR — see scripts/05 and scripts/06.
// This template assumes images with the given tags already exist in ACR.

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Globally unique ACR name (letters/numbers only).')
param acrName string

@description('Globally unique SQL Server name.')
param sqlServerName string

@description('Globally unique Service Bus namespace name.')
param serviceBusNamespaceName string

@description('Your Azure AD email, set as the SQL admin.')
param sqlAdminLogin string

@description('Object ID of the Azure AD principal above (az ad signed-in-user show --query id -o tsv).')
param sqlAdminObjectId string

@description('Image tag to deploy for every service (defaults to "latest").')
param imageTag string = 'latest'

@description('Log Analytics workspace name. Leave the default for a fresh deployment; point it at an existing workspace name to avoid creating a duplicate on a subscription/environment that already has one.')
param logAnalyticsWorkspaceName string = 'log-microservices'

// --- Networking ---
module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
  }
}

// --- ACR ---
module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    location: location
    acrName: acrName
  }
}

// --- Container Apps Environment (VNet-integrated) ---
module containerAppsEnvironment 'modules/containerAppsEnvironment.bicep' = {
  name: 'containerAppsEnvironment'
  params: {
    location: location
    infraSubnetId: network.outputs.infraSubnetId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

// --- Service Bus (namespace, topics, filtered subscriptions) ---
module serviceBus 'modules/serviceBus.bicep' = {
  name: 'serviceBus'
  params: {
    location: location
    namespaceName: serviceBusNamespaceName
  }
}

// Reference the namespace's root connection string for KEDA's scale rule
// auth (a separate concern from each app's own AAD-based ServiceBusClient).
resource sbNamespaceExisting 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: serviceBusNamespaceName
  dependsOn: [serviceBus]
}
resource sbAuthRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2024-01-01' existing = {
  parent: sbNamespaceExisting
  name: 'RootManageSharedAccessKey'
}
var sbConnectionString = sbAuthRule.listKeys().primaryConnectionString

// --- SQL (Private Endpoint, no public access) ---
module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    sqlServerName: sqlServerName
    vnetName: network.outputs.vnetName
    dataSubnetId: network.outputs.dataSubnetId
    adminLogin: sqlAdminLogin
    adminObjectId: sqlAdminObjectId
  }
}

var sqlConnectionString = 'Server=tcp:${sql.outputs.sqlServerFqdn},1433;Database=microservicesdb;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;'
var sbFqdn = serviceBus.outputs.namespaceFqdn

// --- productsapi (external ingress) ---
module productsApi 'modules/containerApp.bicep' = {
  name: 'productsapi'
  params: {
    location: location
    name: 'productsapi'
    environmentId: containerAppsEnvironment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrId: acr.outputs.acrId
    image: '${acr.outputs.acrLoginServer}/productsapi:${imageTag}'
    targetPort: 8080
    ingressExternal: true
    secrets: [
      { name: 'sql-conn', value: sqlConnectionString }
    ]
    envVars: [
      { name: 'ServiceBusNamespace', value: sbFqdn }
      { name: 'UseSqlServer', value: 'true' }
      { name: 'ConnectionStrings__Default', secretRef: 'sql-conn' }
    ]
    minReplicas: 1
    maxReplicas: 5
  }
}

// --- inventory-worker (2 subscriptions: products/inventory-sub + orders/order-created-sub) ---
module inventoryWorker 'modules/containerApp.bicep' = {
  name: 'inventoryWorker'
  params: {
    location: location
    name: 'inventory-worker'
    environmentId: containerAppsEnvironment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrId: acr.outputs.acrId
    image: '${acr.outputs.acrLoginServer}/inventoryworker:${imageTag}'
    secrets: [
      { name: 'sql-conn', value: sqlConnectionString }
      { name: 'servicebus-conn', value: sbConnectionString }
    ]
    envVars: [
      { name: 'ServiceBusNamespace', value: sbFqdn }
      { name: 'ConnectionStrings__Default', secretRef: 'sql-conn' }
    ]
    minReplicas: 0
    maxReplicas: 3
    scaleRules: [
      {
        name: 'products-scaler'
        custom: {
          type: 'azure-servicebus'
          metadata: { topicName: 'products', subscriptionName: 'inventory-sub', namespace: serviceBusNamespaceName, messageCount: '5' }
          auth: [{ secretRef: 'servicebus-conn', triggerParameter: 'connection' }]
        }
      }
      {
        name: 'orders-scaler'
        custom: {
          type: 'azure-servicebus'
          metadata: { topicName: 'orders', subscriptionName: 'order-created-sub', namespace: serviceBusNamespaceName, messageCount: '5' }
          auth: [{ secretRef: 'servicebus-conn', triggerParameter: 'connection' }]
        }
      }
    ]
  }
}

// --- shipping-worker (orders/stock-reserved-sub) ---
module shippingWorker 'modules/containerApp.bicep' = {
  name: 'shippingWorker'
  params: {
    location: location
    name: 'shipping-worker'
    environmentId: containerAppsEnvironment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrId: acr.outputs.acrId
    image: '${acr.outputs.acrLoginServer}/shippingworker:${imageTag}'
    secrets: [
      { name: 'sql-conn', value: sqlConnectionString }
      { name: 'servicebus-conn', value: sbConnectionString }
    ]
    envVars: [
      { name: 'ServiceBusNamespace', value: sbFqdn }
      { name: 'ConnectionStrings__Default', secretRef: 'sql-conn' }
    ]
    minReplicas: 0
    maxReplicas: 3
    scaleRules: [
      {
        name: 'orders-scaler'
        custom: {
          type: 'azure-servicebus'
          metadata: { topicName: 'orders', subscriptionName: 'stock-reserved-sub', namespace: serviceBusNamespaceName, messageCount: '5' }
          auth: [{ secretRef: 'servicebus-conn', triggerParameter: 'connection' }]
        }
      }
    ]
  }
}

// --- notification-worker (products/notification-sub + orders/order-status-sub; no DB access) ---
module notificationWorker 'modules/containerApp.bicep' = {
  name: 'notificationWorker'
  params: {
    location: location
    name: 'notification-worker'
    environmentId: containerAppsEnvironment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrId: acr.outputs.acrId
    image: '${acr.outputs.acrLoginServer}/notificationworker:${imageTag}'
    secrets: [
      { name: 'servicebus-conn', value: sbConnectionString }
    ]
    envVars: [
      { name: 'ServiceBusNamespace', value: sbFqdn }
    ]
    minReplicas: 0
    maxReplicas: 2
    scaleRules: [
      {
        name: 'products-scaler'
        custom: {
          type: 'azure-servicebus'
          metadata: { topicName: 'products', subscriptionName: 'notification-sub', namespace: serviceBusNamespaceName, messageCount: '5' }
          auth: [{ secretRef: 'servicebus-conn', triggerParameter: 'connection' }]
        }
      }
      {
        name: 'orders-scaler'
        custom: {
          type: 'azure-servicebus'
          metadata: { topicName: 'orders', subscriptionName: 'order-status-sub', namespace: serviceBusNamespaceName, messageCount: '5' }
          auth: [{ secretRef: 'servicebus-conn', triggerParameter: 'connection' }]
        }
      }
    ]
  }
}

// --- audit-worker (orders/audit-sub, no filter) ---
module auditWorker 'modules/containerApp.bicep' = {
  name: 'auditWorker'
  params: {
    location: location
    name: 'audit-worker'
    environmentId: containerAppsEnvironment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrId: acr.outputs.acrId
    image: '${acr.outputs.acrLoginServer}/auditworker:${imageTag}'
    secrets: [
      { name: 'sql-conn', value: sqlConnectionString }
      { name: 'servicebus-conn', value: sbConnectionString }
    ]
    envVars: [
      { name: 'ServiceBusNamespace', value: sbFqdn }
      { name: 'ConnectionStrings__Default', secretRef: 'sql-conn' }
    ]
    minReplicas: 0
    maxReplicas: 2
    scaleRules: [
      {
        name: 'audit-scaler'
        custom: {
          type: 'azure-servicebus'
          metadata: { topicName: 'orders', subscriptionName: 'audit-sub', namespace: serviceBusNamespaceName, messageCount: '5' }
          auth: [{ secretRef: 'servicebus-conn', triggerParameter: 'connection' }]
        }
      }
    ]
  }
}

// --- frontend (external ingress; image must be built beforehand with productsapi's FQDN baked in — see scripts/06) ---
module frontend 'modules/containerApp.bicep' = {
  name: 'frontend'
  params: {
    location: location
    name: 'frontend'
    environmentId: containerAppsEnvironment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    acrId: acr.outputs.acrId
    image: '${acr.outputs.acrLoginServer}/frontend:${imageTag}'
    targetPort: 80
    ingressExternal: true
    minReplicas: 1
    maxReplicas: 3
  }
}

// --- RBAC: Service Bus data-plane roles (least privilege per service) ---
var serviceBusDataOwnerRoleId = '090c5cfd-751d-490a-894a-3ce6f1109419'
var serviceBusDataReceiverRoleId = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

resource roleProductsApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sbNamespaceExisting.id, 'productsapi', serviceBusDataOwnerRoleId)
  scope: sbNamespaceExisting
  properties: {
    principalId: productsApi.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataOwnerRoleId)
  }
}

resource roleInventoryWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sbNamespaceExisting.id, 'inventory-worker', serviceBusDataOwnerRoleId)
  scope: sbNamespaceExisting
  properties: {
    principalId: inventoryWorker.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataOwnerRoleId)
  }
}

resource roleShippingWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sbNamespaceExisting.id, 'shipping-worker', serviceBusDataOwnerRoleId)
  scope: sbNamespaceExisting
  properties: {
    principalId: shippingWorker.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataOwnerRoleId)
  }
}

resource roleNotificationWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sbNamespaceExisting.id, 'notification-worker', serviceBusDataReceiverRoleId)
  scope: sbNamespaceExisting
  properties: {
    principalId: notificationWorker.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataReceiverRoleId)
  }
}

resource roleAuditWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sbNamespaceExisting.id, 'audit-worker', serviceBusDataReceiverRoleId)
  scope: sbNamespaceExisting
  properties: {
    principalId: auditWorker.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataReceiverRoleId)
  }
}

output productsApiUrl string = 'https://${productsApi.outputs.fqdn}'
output frontendUrl string = 'https://${frontend.outputs.fqdn}'
