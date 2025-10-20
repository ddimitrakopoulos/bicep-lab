targetScope = 'resourceGroup'

///// PARAMETERS /////

@description('Azure region used for the deployment of all resources')
param location string

@description('Name of the workload that will be deployed')
param workload string

@description('Environment')
param environment string 

@description('Name of the storage account for the table')
param storageAccountTableName string 

@description('Log Workspace name')
param log_workspace_name string 

@description('Key Vault name')
param keyvault_name string 

@description('Table name for Table Storage')
param table_name string 

@description('Log Analytics Workspace SKU')
param log_workspace_sku string 

@description('Number of days to retain data in the Log Analytics Workspace')
param retention_days int

@description('Enable diagnostics settings for resources')
param log_workspace_diagnostics_settings_enabled bool 

@description('Key Vault SKU name')
param keyvault_sku_name string

@description('Enable soft delete for Key Vault')
param keyvault_soft_delete_enabled bool

@description('Enable purge protection for Key Vault')
param keyvault_purge_protection_enabled bool

@description('Enable template deployment access to Key Vault')
param keyvault_enabled_for_template_deployment bool

@description('Enable diagnostics settings for Key Vault')
param keyvault_diagnostics_settings_enabled bool

@description('Private Endpoint name for Key Vault')
param pe_keyvault_name string

///// NETWORK PARAMETERS /////

@description('Virtual Network name')
param vnetName string = '${workload}-${environment}-vnet'

@description('Address space for VNet')
param addressPrefix string = '10.0.0.0/16'

@description('Private Endpoint name for Storage Table')
param pe_table_name string

@description('virtual network name for private endpoints')
param vnet_name string 

@description('App Service name')
param app_service_name string 

@description('App Service Plan name')
param app_service_plan_name string 

@description('App Service SKU name')
param app_service_sku_name string 


///// MODULES /////

// Storage Accounts
module storageAccountTable 'modules/storageAccountTable.bicep' = {
  name: 'stg-table-${workload}-${environment}'
  params: {
    storageAccountName: storageAccountTableName
    location: location
    tags: {
      workload: workload
      environment: environment
    }
    allowPublicAccess: false   // make storage private
  }
}

param name string
param location string
param sku_name string
param soft_delete_enabled bool
param purge_protection_enabled bool
param enabled_for_template_deployment bool
param diagnostics_settings_enabled bool
param log_workspace_id string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: sku_name
    }
    tenantId: subscription().tenantId
    enableSoftDelete: soft_delete_enabled
    enablePurgeProtection: purge_protection_enabled
    enabledForTemplateDeployment: enabled_for_template_deployment
  }
}

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = [for secret in [
  {
    name: 'MySecret1'
    value: 'secret-value-1'
  }
  {
    name: 'MySecret2'
    value: 'secret-value-2'
  }
]: {
  name: '${keyVault.name}/${secret.name}'
  properties: {
    value: secret.value
  }
  dependsOn: [
    keyVault
  ]
}]


// Log Analytics
module log_workspace 'modules/log_workspace.bicep' = {
  name: 'log-workspace-deployment'
  params: {
    name: log_workspace_name
    location: location
    sku: log_workspace_sku
    retention_days: retention_days
    diagnostics_settings_enabled: log_workspace_diagnostics_settings_enabled
  }
}

// Key Vault
module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    name: keyvault_name
    location: location
    sku_name: keyvault_sku_name
    soft_delete_enabled: keyvault_soft_delete_enabled
    purge_protection_enabled: keyvault_purge_protection_enabled
    enabled_for_template_deployment: keyvault_enabled_for_template_deployment
    diagnostics_settings_enabled: keyvault_diagnostics_settings_enabled
    log_workspace_id: log_workspace.outputs.log_workspace_id
  }
}

// Table Storage
module table 'modules/tableStorage.bicep' = {
  name: 'createTable-${workload}'
  dependsOn: [ storageAccountTable ]
  params: {
    storageAccountName: storageAccountTableName
    tableName: table_name
  }
}

///// NETWORK MODULES /////

// Virtual Network
module vnet './modules/vnet.bicep' = {
  name: vnet_name
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: addressPrefix
    tags: {
      workload: workload
      environment: environment
    }
  }
}

///// PRIVATE ENDPOINT MODULES /////


resource peStorageTable 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: pe_table_name
  location: location
  dependsOn: [storageAccountTable, vnet]
  properties: {
    subnet: {
      id: vnet.outputs.subnet_ids['private-endpoints']
    }
    privateLinkServiceConnections: [
      {
        name: 'table-connection'
        properties: {
          privateLinkServiceId: storageAccountTable.outputs.storageAccountId
          groupIds: ['table']
        }
      }
    ]
    privateDnsZoneGroups: [
      {
        name: 'table-dns-group'
        properties: {
          privateDnsZoneConfigs: [
            {
              name: 'tableZoneConfig'
              properties: {
                privateDnsZoneId: dnsZoneTable.id
              }
            }
          ]
        }
      }
    ]
  }
}

resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: pe_keyvault_name
  location: location
  properties: {
    subnet: {
      id: vnet.outputs.subnet_ids['private-endpoints']
    }
    privateLinkServiceConnections: [
      {
        name: 'keyvault-connection'
        properties: {
          privateLinkServiceId: keyvault.outputs.keyvaultId
          groupIds: ['vault']
        }
      }
    ]
    privateDnsZoneGroups: [
      {
        name: 'kv-dns-group'
        properties: {
          privateDnsZoneConfigs: [
            {
              name: 'kvZoneConfig'
              properties: {
                privateDnsZoneId: dnsZoneVault.id
              }
            }
          ]
        }
      }
    ]
  }
}


resource dnsZoneVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource dnsZoneTable 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.core.windows.net'
  location: 'global'
}

// Link zones to your VNet
resource dnsZoneLinkVault 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-vault'
  parent: dnsZoneVault
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.outputs.vnet_id
    }
    registrationEnabled: false
  }
}

resource dnsZoneLinkTable 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-table'
  parent: dnsZoneTable
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.outputs.vnet_id
    }
    registrationEnabled: false
  }
}

// App Service (frontend + backend)
module appServiceModule './modules/app_service.bicep' = {
  name: 'deployAppService'
  params: {
    appServiceName: app_service_name
    appServicePlanName: app_service_plan_name
    skuName: app_service_sku_name
    location: location
    nodeVersion: '~20'
    subnetId: vnet.outputs.subnet_ids['appservice']
  }
  dependsOn: [
    keyvault
    storageAccountTable
  ]
}

///// OUTPUTS /////

output subnet_ids object = vnet.outputs.subnet_ids
output storageTableId string = storageAccountTable.outputs.storageAccountId


