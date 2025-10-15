targetScope = 'resourceGroup'

///// PARAMETERS /////

@description('Azure region used for the deployment of all resources')
param location string

@description('Name of the workload that will be deployed')
param workload string

@description('sku for the Static Web App')
param web_app_sku string

@description('Enable config file updates')
param allowConfigUpdates bool

@description('Repository branch (for GitHub integration).')
param branch string 

@description('GitHub repository URL for the TS app')
param repositoryUrl string 

@description('Environment')
param environment string 

@description('Name of the storage account for the table')
param storageAccountTableName string 

@description('Name of the storage account for the functions')
param storageAccountFunctionName string 

@description('Static Web App Name')
param staticWebAppName string  

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

@description('Name for function app doing CRUD operations')
param function_name_crud string 

@description('Runtime stack for crud function (e.g., dotnet, node, python)')
param function_runtime_crud string 

@description('Name for function app doing Login operations')
param function_name_login string

@description('Runtime stack for login function (e.g., dotnet, node, python)')
param function_runtime_login string

@description('Private Endpoint name for Key Vault')
param pe_keyvault_name string

///// NETWORK PARAMETERS /////

@description('Virtual Network name')
param vnetName string = '${workload}-${environment}-vnet'

@description('Address space for VNet')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet configurations')
param subnets array = [
  {
    name: 'default'
    prefix: '10.0.1.0/24'
  }
  {
    name: 'storage'
    prefix: '10.0.2.0/24'
  }
  {
    name: 'functions'
    prefix: '10.0.3.0/24'
  }
  {
    name: 'private-endpoints'
    prefix: '10.0.4.0/24'
  }
]

@description('Private Endpoint name for Storage Table')
param pe_table_name string

@description('virtual network name for private endpoints')
param vnet_name string 
///// MODULES /////

// Static Web App
module staticAppModule './modules/staticWebApp.bicep' = {
  name: 'deployStaticWebApp'
  params: {
    name: staticWebAppName
    sku: web_app_sku
    allowConfigFileUpdates: allowConfigUpdates
    location: location
    repositoryUrl: repositoryUrl
    branch: branch
  }
}

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

module storageAccountFunction 'modules/storageAccountFunction.bicep' = {
  name: 'stg-fun${workload}-${environment}'
  params: {
    storageAccountName: storageAccountFunctionName
    location: location
    tags: {
      workload: workload
      environment: environment
    }
    allowPublicAccess: false   // make storage private
  }
}

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

// CRUD Function App
module function_module_crud './modules/function.bicep' = {
  name: 'deploy_crud_function-${workload}'
  dependsOn: [ storageAccountFunction, vnet, staticAppModule ]
  params: {
    functionAppName: function_name_crud
    storageAccountName: storageAccountFunctionName
    runtime: function_runtime_crud
    vnetIntegrationSubnetId: vnet.outputs.subnet_ids['functions']
    enableEasyAuth: true
    allowedCallerClientId: staticAppModule.outputs.staticWebAppPrincipalId
  }
}

// LOGIN Function App
module function_module_login './modules/function.bicep' = {
  name: 'deploy_login_function-${workload}'
  dependsOn: [ storageAccountFunction, vnet, staticAppModule ]
  params: {
    functionAppName: function_name_login
    storageAccountName: storageAccountFunctionName
    runtime: function_runtime_login
    vnetIntegrationSubnetId: vnet.outputs.subnet_ids['functions']
    enableEasyAuth: true
    allowedCallerClientId: staticAppModule.outputs.staticWebAppPrincipalId
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
    subnets: subnets
    tags: {
      workload: workload
      environment: environment
    }
  }
}

///// PRIVATE ENDPOINT MODULES /////


// DNS Zones
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

// Private Endpoints
module peStorage './modules/private_endpoint.bicep' = {
  name: 'peStorageModule'
  params: {
    peName: pe_table_name
    location: location
    subnetId: vnet.outputs.subnet_ids['functions']
    privateLinkServiceId: storageAccountTable.outputs.storageAccountId
    groupIds: ['table']
    dnsZoneId: dnsZoneTable.id
    dnsGroupName: 'table-dns-group'
    connectionName: 'table-connection'
  }
  dependsOn: [
    storageAccountTable
    vnet
  ]
}

module peKeyVault './modules/private_endpoint.bicep' = {
  name: 'peKeyVaultModule'
  params: {
    peName: pe_keyvault_name
    location: location
    subnetId: vnet.outputs.subnet_ids['functions']
    privateLinkServiceId: keyvault.outputs.keyvaultId
    groupIds: ['vault']
    dnsZoneId: dnsZoneVault.id
    dnsGroupName: 'kv-dns-group'
    connectionName: 'keyvault-connection'
  }
  dependsOn: [
    keyvault
    vnet
  ]
}


///// OUTPUTS /////

output subnet_ids object = vnet.outputs.subnet_ids
output storageTableId string = storageAccountTable.outputs.storageAccountId
output storageFunctionId string = storageAccountFunction.outputs.storageAccountId
output crudFunctionName string = function_module_crud.outputs.functionAppName
output loginFunctionName string = function_module_login.outputs.functionAppName
