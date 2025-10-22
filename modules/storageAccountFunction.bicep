@description('Name of the storage account. Must be globally unique and 3–24 lowercase letters and numbers.')
param storageAccountName string

@description('Location for the storage account.')
param location string

@description('Resource tags (optional).')
param tags object = {}

@description('Kind of storage account.')
param kind string = 'StorageV2'

@description('Replication type: LRS (default), GRS, RAGRS, ZRS, GZRS, RAGZRS')
param skuName string = 'Standard_LRS'

@description('Allow public blob access (default: false)')
param allowPublicAccess bool = false

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    alloPublicAccess: allowPublicAccess
    accessTier: 'Hot'
  }
  tags: tags
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
