targetScope = 'resourceGroup'

//============================================================================
// PARAMETERS
//============================================================================

// Core deployment parameters
@description('Azure region where all resources will be deployed')
param location string

@description('Name of the workload used as naming prefix')
param workloadName string

@description('Environment designation (dev, test, prod)')
param environment string

// Log Analytics workspace parameters
@description('Name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('SKU for the Log Analytics workspace')
param logAnalyticsWorkspaceSku string

@description('Number of days to retain data in the Log Analytics workspace')
param logAnalyticsRetentionInDays int

@description('Enable diagnostic settings for resources')
param diagnosticsEnabled bool

// Storage Account parameters
@description('Name of the storage account for table storage')
param storageAccountName string

@description('Name of the storage table')
param storageTableName string

// Key Vault parameters
@description('Name of the Key Vault')
param keyVaultName string

@description('SKU name for the Key Vault')
param keyVaultSku string

@description('Enable soft delete functionality for Key Vault')
param keyVaultSoftDeleteEnabled bool

@description('Enable purge protection for Key Vault')
param keyVaultPurgeProtectionEnabled bool

@description('Enable Azure Resource Manager template deployment access to Key Vault')
param keyVaultEnabledForTemplateDeployment bool

// Network parameters
@description('Name of the virtual network')
param virtualNetworkName string

@description('Address space for the virtual network')
param virtualNetworkAddressPrefix string

// Private Endpoint parameters
@description('Name of the private endpoint for storage table')
param storageTablePrivateEndpointName string

@description('Name of the private endpoint for Key Vault')
param keyVaultPrivateEndpointName string

// App Service parameters
@description('Name of the App Service web application')
param appServiceName string

@description('Name of the App Service hosting plan')
param appServicePlanName string

@description('SKU name for the App Service hosting plan')
param appServiceSkuName string

// Secret parameters
@secure()
@description('JWT secret for application authentication')
param jwtsecret string

@secure()
@description('Password for ddimitr user')
param ddimitrpass string

@secure()
@description('Password for hello user')
param hellopass string


//============================================================================
// INFRASTRUCTURE MODULES
//============================================================================

// Log Analytics workspace (deployed first for diagnostics)
module logAnalyticsWorkspaceModule 'modules/logAnalyticsWorkspace.bicep' = {
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    location: location
    skuName: logAnalyticsWorkspaceSku
    retentionInDays: logAnalyticsRetentionInDays
    diagnosticsEnabled: diagnosticsEnabled
  }
}

// Virtual Network
module virtualNetworkModule 'modules/virtualNetwork.bicep' = {
  params: {
    virtualNetworkName: virtualNetworkName
    location: location
    addressPrefix: virtualNetworkAddressPrefix
    tags: {
      workload: workloadName
      environment: environment
    }
  }
}

// Storage Account for table storage
module storageAccountModule 'modules/storageAccount.bicep' = {
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: {
      workload: workloadName
      environment: environment
    }
    allowBlobPublicAccess: false   
    publicNetworkAccess: 'Disabled'
    diagnosticsEnabled: diagnosticsEnabled
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceModule.outputs.log_workspace_id
  }
}

// Storage Table (depends on Storage Account)
module storageTableModule 'modules/storageTable.bicep' = {
  dependsOn: [ storageAccountModule ]
  params: {
    storageAccountName: storageAccountName
    storageTableName: storageTableName
  }
}

// Key Vault
module keyVaultModule 'modules/keyVault.bicep' = {
  params: {
    keyVaultName: keyVaultName
    location: location
    skuName: keyVaultSku
    softDeleteEnabled: keyVaultSoftDeleteEnabled
    purgeProtectionEnabled: keyVaultPurgeProtectionEnabled
    enabledForTemplateDeployment: keyVaultEnabledForTemplateDeployment
    diagnosticsEnabled: diagnosticsEnabled
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceModule.outputs.log_workspace_id
  }
}

// Key Vault Secrets
resource jwtSecretResource 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: '${keyVaultName}/jwtsecret'
  properties: {
    value: jwtsecret
  }
  dependsOn: [
    keyVaultModule
  ]
}

resource ddimitrPasswordResource 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: '${keyVaultName}/ddimitrpass'
  properties: {
    value: ddimitrpass
  }
  dependsOn: [
    keyVaultModule
  ]
}

resource helloPasswordResource 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: '${keyVaultName}/hellopass'
  properties: {
    value: hellopass
  }
  dependsOn: [
    keyVaultModule
  ]
}

// App Service web application
module appServiceModule 'modules/appService.bicep' = {
  params: {
    appServiceName: appServiceName
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServiceSkuName
    location: location
    nodeJsVersion: '~20'
    subnetId: virtualNetworkModule.outputs.subnet_ids.appservice
    diagnosticsEnabled: diagnosticsEnabled
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceModule.outputs.log_workspace_id
  }
  dependsOn: [
    keyVaultModule
    storageAccountModule
  ]
}

//============================================================================
// PRIVATE NETWORKING
//============================================================================

// Private DNS zones for private endpoints
resource privateDnsZoneVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource privateDnsZoneTable 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table${az.environment().suffixes.storage}'
  location: 'global'
}

// Link DNS zones to virtual network
resource privateDnsZoneVaultVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vault-vnet-link'
  parent: privateDnsZoneVault
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkModule.outputs.vnet_id
    }
    registrationEnabled: false
  }
}

resource privateDnsZoneTableVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'table-vnet-link'
  parent: privateDnsZoneTable
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkModule.outputs.vnet_id
    }
    registrationEnabled: false
  }
}

// Private endpoint for storage table
resource storageTablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: storageTablePrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: virtualNetworkModule.outputs.subnet_ids.privateEndpoints
    }
    privateLinkServiceConnections: [
      {
        name: 'table-connection'
        properties: {
          privateLinkServiceId: storageAccountModule.outputs.storageAccountId
          groupIds: ['table']
        }
      }
    ]
  }
}

// Private endpoint for Key Vault
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: virtualNetworkModule.outputs.subnet_ids.privateEndpoints
    }
    privateLinkServiceConnections: [
      {
        name: 'keyvault-connection'
        properties: {
          privateLinkServiceId: keyVaultModule.outputs.keyvaultId
          groupIds: ['vault']
        }
      }
    ]
  }
}

// DNS A records for private endpoints
resource dnsRecordVault 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: keyVaultName
  parent: privateDnsZoneVault
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: keyVaultPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

resource dnsRecordTable 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: storageAccountName
  parent: privateDnsZoneTable
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: storageTablePrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

//============================================================================
// OUTPUTS
//============================================================================

output subnetIds object = virtualNetworkModule.outputs.subnet_ids
output storageAccountId string = storageAccountModule.outputs.storageAccountId
output keyVaultId string = keyVaultModule.outputs.keyvaultId
output appServicePrincipalId string = appServiceModule.outputs.appServicePrincipalId
output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceModule.outputs.log_workspace_id

