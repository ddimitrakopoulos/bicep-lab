@description('Name of the Function App')
param functionAppName string

@description('Name of the storage account used by the Function App')
param storageAccountName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Runtime stack (e.g., dotnet, node, python)')
@allowed([
  'dotnet'
  'node'
  'python'
])
param runtime string = 'dotnet'

@description('Optional tags')
param tags object = {}

var hostingPlanName = '${functionAppName}-plan'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1' // Consumption Plan (Dynamic)
    tier: 'Dynamic'
  }
  tags: tags
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.properties.primaryEndpoints.blob
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}

output functionAppName string = functionApp.name
output functionAppPrincipalId string = functionApp.identity.principalId
output functionAppId string = functionApp.id
output functionAppUrl string = 'https://${functionApp.name}.azurewebsites.net'
