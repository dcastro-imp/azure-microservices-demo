param location string
param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false // Container Apps pull via Managed Identity + AcrPull, not admin credentials.
  }
}

output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
