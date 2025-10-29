targetScope = 'resourceGroup'

//============================================================================
// PARAMETERS
//============================================================================

@description('Name of the existing Key Vault')
param keyVaultName string

@description('Name of the existing App Service web application')
param appServiceName string

@description('Name of the existing Storage Account')
param storageAccountName string

//============================================================================
// EXISTING RESOURCES
//============================================================================

// Reference to existing Key Vault
resource keyVaultResource 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}

// Reference to existing App Service
resource appServiceResource 'Microsoft.Web/sites@2023-12-01' existing = {
  name: appServiceName
}

// Reference to existing Storage Account
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

//============================================================================
// ROLE ASSIGNMENTS
//============================================================================

// Assign Key Vault Secrets User role to App Service managed identity
resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('KeyVault-SecretsUser', appServiceResource.name, keyVaultResource.name)
  scope: keyVaultResource
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    principalId: appServiceResource.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign Storage Table Data Contributor role to App Service managed identity
resource storageTableDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Storage-TableDataContributor', appServiceResource.name, storageAccountResource.name)
  scope: storageAccountResource
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Storage Table Data Contributor
    )
    principalId: appServiceResource.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

//============================================================================
// OUTPUTS
//============================================================================

output keyVaultRoleAssignmentId string = keyVaultSecretsUserRoleAssignment.id
output storageRoleAssignmentId string = storageTableDataContributorRoleAssignment.id
