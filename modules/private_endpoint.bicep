@description('Name of the private endpoint')
param privateEndpointName string

@description('ID of the target resource (Storage, KeyVault, SQL, etc.)')
param targetResourceId string

@description('Subnet ID where the private endpoint will be deployed')
param subnetId string

@description('List of groupIds for the service (e.g., ["vault"] for Key Vault, ["blob","table"] for Storage)')
param groupIds array

@description('Location for the private endpoint')
param location string = resourceGroup().location

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-conn'
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: groupIds
          requestMessage: 'Please approve my connection'
          privateLinkServiceConnectionState: {
            status: 'Pending'
            description: 'Awaiting approval'
          }
        }
      }
    ]
  }
}

