targetScope = 'resourceGroup'

///// PARAMETERS /////

@description('Azure region used for the deployment of all resources')
param location string

@description('Name of the workload that will be deployed')
param workload string

@description('sku for the Static Web App')
param sku string

@description('Enable config file updates')
param allowConfigUpdates bool

@description('Repository branch (for GitHub integration).')
param branch string 

@description('GitHub repository URL for the TS app')
param repositoryUrl string 

@description('Environment')
param environment string = 'dev'

@description('Name of the storage account. Must be globally unique and 3–24 lowercase letters and numbers.')
param storageAccountName string = 'stacc${toLower(workload)}'
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
    name: 'static-wapp-${workload}'
    sku: sku
    allowConfigFileUpdates: allowConfigUpdates
    location: location
    repositoryUrl: repositoryUrl
    branch: branch
  }
}

module log_workspace 'modules/log_workspace.bicep' = {
  name: 'log-workspace-deployment'
  params: {
    name: 'log-${workload}'
    location: location
    sku: 'PerGB2018'
    retention_days: 30
    diagnostics_settings_enabled: true
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    name: 'kv-${workload}'
    location: location
    sku_name: 'standard'

    soft_delete_enabled: true
    purge_protection_enabled: true
    enabled_for_template_deployment: false

    diagnostics_settings_enabled: true
    log_workspace_id: log_workspace.outputs.log_workspace_id
  }
}

module table 'modules/tableStorage.bicep' = {
  name: 'createTable-${workload}'
  dependsOn: [ storage ]
  params: {
    storageAccountName: storageAccountName
    tableName: 'table${workload}'
  }
}

module appservice 'modules/appService.bicep' = {
  name: 'appservice-${workload}'
  params: {
    appServicePlanName: 'asp-${workload}-${environment}'
    webAppName: 'app-${workload}-${environment}'
    location: location
    containerImage: 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
    tags: {
      workload: workload
      environment: environment
    }
  }
}


///// OUTPUTS /////
