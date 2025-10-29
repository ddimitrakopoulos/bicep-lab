targetScope = 'resourceGroup'

@description('Name of the existing Key Vault')
param keyVaultName string

@description('Name of the existing Web App')
param webAppName string

@description('Name of the existing Storage Account')
param storageAccountName string

@description('Workload identifier')
param workload string

@description('Environment (e.g., dev, test, prod)')
param environment string

// ─────────────────────────────────────────────────────────────
// Existing resources
// ─────────────────────────────────────────────────────────────

// Existing Key Vault
resource existingKeyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
}

// Existing Web App
resource existingWebApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: webAppName
}

// Existing Storage Account
resource existingStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// ─────────────────────────────────────────────────────────────
// Role Assignments
// ─────────────────────────────────────────────────────────────

// Key Vault Secrets User
resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Keyvault Secret User', existingWebApp.name, existingKeyVault.name)
  scope: existingKeyVault
  location: resourceGroup().location
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' 
    )
    principalId: existingWebApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Table Data Contributor
resource storageTableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Storage Table Data Contributor', existingWebApp.name, existingStorage.name)
  scope: existingStorage
  location: resourceGroup().location
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' 
    )
    principalId: existingWebApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
