// Generic Container App module, reused for all 5 backend services + the
// frontend. Each caller passes its own image, env vars, ingress needs and
// KEDA scale rules — see main.bicep for how each of the 6 apps is wired up.

param location string
param name string
param environmentId string
param acrLoginServer string
param acrId string
param image string
param targetPort int = 0
param ingressExternal bool = false
@description('Plain (non-secret) environment variables.')
param envVars array = []
@description('Secrets, e.g. [{ name: \'sql-conn\', value: \'...\' }]. Referenced from envVars via secretRef.')
param secrets array = []
param minReplicas int = 0
param maxReplicas int = 3
@description('KEDA scale rules, e.g. [{ name: \'orders-scaler\', serviceBusQueueName: ..., custom: {...} }] — see main.bicep for the azure-servicebus rule shape.')
param scaleRules array = []

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      secrets: secrets
      registries: [
        {
          server: acrLoginServer
          identity: 'system'
        }
      ]
      ingress: ingressExternal ? {
        external: true
        targetPort: targetPort
        transport: 'Auto'
      } : null
    }
    template: {
      containers: [
        {
          name: name
          image: image
          env: envVars
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: scaleRules
      }
    }
  }
}

// Grants this app's own Managed Identity permission to pull from ACR —
// the CLI's `--registry-identity system` flag does this automatically;
// in Bicep it must be created explicitly.
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, name, 'AcrPull')
  scope: resourceGroup()
  properties: {
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

output principalId string = containerApp.identity.principalId
output fqdn string = ingressExternal ? containerApp.properties.configuration.ingress.fqdn : ''
