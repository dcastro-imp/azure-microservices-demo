// VNet + 2 subnets (infra for Container Apps, data for Private Endpoints) + NSG.
// See docs/AZURE-LEARNING-GUIDE.md "Proyecto 3b" for the concepts.

param location string
param vnetName string = 'vnet-microservices'
param nsgName string = 'nsg-infra-subnet'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  // No custom rules: Azure's default rules already deny all inbound from the
  // internet and allow intra-VNet traffic — see the guide for the exact list.
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'infra-subnet'
        properties: {
          addressPrefix: '10.0.0.0/23'
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'data-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output infraSubnetId string = vnet.properties.subnets[0].id
output dataSubnetId string = vnet.properties.subnets[1].id
