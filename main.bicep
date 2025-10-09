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

@description('Name of the storage account. Must be globally unique and 3–24 lowercase letters and numbers.')
param storageAccountName string 

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

@description('Name of the App Service Plan')
param app_service_plan_name string

@description('Name of the Web App')
param web_app_name string

@description('Container image for the Web App (e.g., myregistry.azurecr.io/myapp:latest)')
param app_service_container_image string

@description('Name of the Virtual Network')
param vnet_name string


///// VARIABLES /////

///// MODULES /////


module storage 'modules/storageAccount.bicep' = {
  name: 'stg-${workload}-${environment}'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: {
      workload: workload
      environment: environment
    }
  }
}


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

module keyvaultPE 'modules/privateEndpoint.bicep' = {
  name: 'kv-private-endpoint'
  params: {
    privateEndpointName: 'kv-pe-${workload}'
    targetResourceId: keyvault.outputs.keyvaultId
    subnetId: vnet.outputs.subnet_ids['private-endpoints']
    groupIds: [ 'vault' ]
  }
}


module table 'modules/tableStorage.bicep' = {
  name: 'createTable-${workload}'
  dependsOn: [ storage ]
  params: {
    storageAccountName: storageAccountName
    tableName: table_name
  }
}

module appservice 'modules/appService.bicep' = {
  name: 'appservice-${workload}'
  params: {
    appServicePlanName: app_service_plan_name
    webAppName: web_app_name
    location: location
    containerImage: app_service_container_image
    tags: {
      workload: workload
      environment: environment
    }
  }
}

module vnet 'modules/virtualNetwork.bicep' = {
  name: 'vnet-${workload}-${environment}'
  params: {
    vnetName: vnet_name
    location: location
    tags: {
      workload: workload
      environment: environment
    }
  }
}


///// OUTPUTS /////
