//============================================================================
// PARAMETERS
//============================================================================

@description('Name of the Storage Account')
param storageAccountName string

@description('Location where the Storage Account will be deployed')
param location string = resourceGroup().location

@description('Tags to apply to the Storage Account')
param tags object = {}

@description('Allow public access to blobs')
param allowBlobPublicAccess bool = false

@description('Allow public network access to the Storage Account')
param publicNetworkAccess string = 'Disabled'

//============================================================================
// RESOURCES
//============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: tags
  properties: {
    allowBlobPublicAccess: allowBlobPublicAccess
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

//============================================================================
// OUTPUTS
//============================================================================

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
