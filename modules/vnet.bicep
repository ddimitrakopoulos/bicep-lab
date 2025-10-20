@description('Name of the Virtual Network')
param vnetName string

@description('Location for the VNet')
param location string

@description('Address space for the VNet')
param addressPrefix string = '10.0.0.0/16'

@description('Tags for resources')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
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

output subnet_ids object = {
  appservice: vnet.properties.subnets[0].id
  'private-endpoints': vnet.properties.subnets[1].id
}

output vnet_id string = vnet.id
