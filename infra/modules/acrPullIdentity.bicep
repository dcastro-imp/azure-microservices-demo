// A shared User-Assigned Managed Identity used ONLY for pulling images from
// ACR. Necessary because a Container App's own System-Assigned identity
// doesn't exist yet at the moment ARM needs to pull the image to start the
// very first revision — granting AcrPull to it would be a circular
// dependency (see docs/AZURE-LEARNING-GUIDE.md "Proyecto 4"). A
// User-Assigned identity's principal exists independently of any Container
// App, so it can receive the role BEFORE any app references it.

param location string
param acrId string

resource acrPullIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-acr-pull'
  location: location
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, 'id-acr-pull', 'AcrPull')
  scope: resourceGroup()
  properties: {
    principalId: acrPullIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

output identityId string = acrPullIdentity.id
