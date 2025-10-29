//============================================================================
// PARAMETERS
//============================================================================

@minLength(3)
@maxLength(24)
@description('Name of the Key Vault')
param keyVaultName string

@description('Location where the Key Vault will be deployed')
param location string

@allowed([
  'premium'
  'standard'
])
@description('SKU name for the Key Vault')
param skuName string

@description('Enable Azure Resource Manager template deployment access to Key Vault')
param enabledForTemplateDeployment bool

@description('Enable purge protection for the Key Vault')
param purgeProtectionEnabled bool

@description('Enable soft delete functionality for the Key Vault')
param softDeleteEnabled bool

@description('Resource ID of the Log Analytics workspace for diagnostic settings')
param logAnalyticsWorkspaceId string

@description('Enable diagnostic settings for the Key Vault')
param diagnosticsEnabled bool

//============================================================================
// RESOURCES
//============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: subscription().tenantId

    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: purgeProtectionEnabled ? true : null
    publicNetworkAccess: 'Disabled'
    enableSoftDelete: softDeleteEnabled
    enableRbacAuthorization: true
    networkAcls: {
      bypass: enabledForTemplateDeployment ? 'AzureServices' : 'None'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }

    accessPolicies: []
  }
}

resource keyVaultDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (diagnosticsEnabled) {
  name: '${keyVaultName}-diagnostics'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

//============================================================================
// OUTPUTS
//============================================================================

output keyvaultId string = keyVault.id
output keyVaultName string = keyVault.name
