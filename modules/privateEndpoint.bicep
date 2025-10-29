//============================================================================
// PARAMETERS
//============================================================================

@description('Name of the private endpoint')
param privateEndpointName string

@description('Resource ID of the target service (Storage Account, Key Vault, SQL Server, etc.)')
param targetResourceId string

@description('Resource ID of the subnet where the private endpoint will be deployed')
param subnetId string

@description('List of group IDs for the private link service (e.g., ["vault"] for Key Vault, ["table"] for Storage Table)')
param groupIds array

@description('Location where the private endpoint will be deployed')
param location string = resourceGroup().location

//============================================================================
// RESOURCES
//============================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
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

//============================================================================
// OUTPUTS
//============================================================================

output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name

