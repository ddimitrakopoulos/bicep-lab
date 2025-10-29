//============================================================================
// PARAMETERS
//============================================================================

@description('Name of the Virtual Network')
param virtualNetworkName string

@description('Location where the Virtual Network will be deployed')
param location string

@description('Address space for the Virtual Network')
param addressPrefix string = '10.0.0.0/16'

@description('Tags to apply to the Virtual Network')
param tags object = {}

//============================================================================
// RESOURCES
//============================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      // Subnet for App Service VNet Integration and Private Endpoints
      {
        name: 'appservice'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'webapp-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }

      // Subnet for other private endpoints (Key Vault, Storage, etc.)
      {
        name: 'private-endpoints'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
  tags: tags
}

//============================================================================
// OUTPUTS
//============================================================================

output subnet_ids object = {
  appservice: virtualNetwork.properties.subnets[0].id
  privateEndpoints: virtualNetwork.properties.subnets[1].id
}

output vnet_id string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
