@description('Name of the existing storage account that will host the table')
param storageAccountName string

@description('Name of the table to create. Must match pattern: ^[A-Za-z][A-Za-z0-9]{2,62}$')
param tableName string

@description('Table signed identifiers for access policies (optional)')
param signedIdentifiers array = []

// Reference the existing storage account
resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Reference the Table service ("default") as the parent
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2025-01-01' existing = {
  parent: stg
  name: 'default'
}

// Create the table
resource tableResource 'Microsoft.Storage/storageAccounts/tableServices/tables@2025-01-01' = {
  parent: tableService
  name: tableName
  properties: {
    // optional signed identifiers (stored access policies)
    signedIdentifiers: signedIdentifiers
  }
}

// Expose useful outputs
output tableName string = tableResource.name
output tableResourceId string = tableResource.id
