//============================================================================
// PARAMETERS
//============================================================================

@description('Name of the App Service web application')
param appServiceName string

@description('Name of the App Service hosting plan')
param appServicePlanName string

@description('Location where the App Service resources will be deployed')
param location string

@description('SKU for the App Service hosting plan')
param appServicePlanSkuName string = 'B1'

@description('Node.js runtime version for the App Service')
param nodeJsVersion string = '~20'

@description('Subnet resource ID for VNet integration')
param subnetId string

@description('Enable diagnostic settings for App Service resources')
param diagnosticsEnabled bool = false

@description('Resource ID of the Log Analytics workspace for diagnostic settings')
param logAnalyticsWorkspaceId string = ''

//============================================================================
// RESOURCES
//============================================================================

// Create the App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Create the Web App (without source control or deployment)
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeJsVersion}'
      appSettings: [
        {
          name: 'PORT'
          value: '8080'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
      ]
      vnetRouteAllEnabled: true
    }
  }
}

// Integrate App Service with VNet subnet
resource vnetIntegration 'Microsoft.Web/sites/networkConfig@2022-09-01' = {
  parent: webApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetId
  }
}

// App Service diagnostic settings
resource appServiceDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (diagnosticsEnabled && !empty(logAnalyticsWorkspaceId)) {
  name: '${appServiceName}-diagnostics'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// App Service Plan diagnostic settings
resource appServicePlanDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (diagnosticsEnabled && !empty(logAnalyticsWorkspaceId)) {
  name: '${appServicePlanName}-diagnostics'
  scope: appServicePlan
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

//============================================================================
// OUTPUTS
//============================================================================

output appServiceId string = webApp.id
output appServiceName string = webApp.name
output appServicePlanId string = appServicePlan.id
output appServicePrincipalId string = webApp.identity.principalId

