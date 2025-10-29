//============================================================================
// PARAMETERS
//============================================================================

@description('Name of the existing Storage Account that will host the table')
param storageAccountName string

@description('Name of the table to create (must match pattern: ^[A-Za-z][A-Za-z0-9]{2,62}$)')
param storageTableName string

@description('Table signed identifiers for access policies')
param signedIdentifiers array = []

//============================================================================
// RESOURCES
//============================================================================

// Reference the existing Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Reference the Table service ("default") as the parent
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2025-01-01' existing = {
  parent: storageAccount
  name: 'default'
}

// Create the table
resource tableResource 'Microsoft.Storage/storageAccounts/tableServices/tables@2025-01-01' = {
  parent: tableService
  name: storageTableName
  properties: {
    signedIdentifiers: signedIdentifiers
  }
}

//============================================================================
// OUTPUTS
//============================================================================

output tableName string = tableResource.name
output tableResourceId string = tableResource.id
