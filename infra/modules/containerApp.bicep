// Generic Container App module, reused for all 5 backend services + the
// frontend. Each caller passes its own image, env vars, ingress needs and
// KEDA scale rules — see main.bicep for how each of the 6 apps is wired up.

param location string
param name string
param environmentId string
param acrLoginServer string
@description('Resource ID of the shared User-Assigned Identity used to pull from ACR (see modules/acrPullIdentity.bicep) — must already have AcrPull granted BEFORE this app is created, since a System-Assigned identity would not exist yet at image-pull time.')
param acrPullIdentityId string
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
    // SystemAssigned: this app's own identity, used for Service Bus/SQL access.
    // UserAssigned (id-acr-pull): pre-existing identity, already granted
    // AcrPull, used ONLY so the platform can pull the image at creation time.
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${acrPullIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      secrets: secrets
      registries: [
        {
          server: acrLoginServer
          identity: acrPullIdentityId
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

output principalId string = containerApp.identity.principalId
output fqdn string = ingressExternal ? containerApp.properties.configuration.ingress.fqdn : ''
