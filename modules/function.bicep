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

@description('Optional subnet ID for VNet Integration')
param vnetIntegrationSubnetId string = ''

@description('Optional tags')
param tags object = {}

@description('Enable Easy Auth (AAD) for the function')
param enableEasyAuth bool = false

@description('AAD Client ID of the frontend app (Static Web App) allowed to access this function')
param allowedCallerClientId string = ''

var hostingPlanName = '${functionAppName}-plan'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  tags: tags
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: union({
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=core.windows.net'
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
    }, empty(vnetIntegrationSubnetId) ? {} : {
      virtualNetworkSubnetId: vnetIntegrationSubnetId
    })
  }
  tags: tags
}

resource easyAuth 'Microsoft.Web/sites/config@2022-09-01' = if (enableEasyAuth) {
  name: '${functionAppName}/authsettingsV2'
  properties: {
    platform: {
      enabled: true
      runtimeVersion: '~1'
    }
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'RedirectToLoginPage'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: 'https://login.microsoftonline.com/${tenant().tenantId}/v2.0'
          clientId: allowedCallerClientId
        }
        validation: {
          allowedAudiences: [
            allowedCallerClientId
          ]
        }
      }
    }
    login: {
      tokenStore: {
        enabled: true
      }
    }
  }
  dependsOn: [functionApp]
}

///// OUTPUTS /////
output functionAppName string = functionApp.name
output functionAppPrincipalId string = functionApp.identity.principalId
output functionAppId string = functionApp.id
output functionAppUrl string = 'https://${functionApp.name}.azurewebsites.net'
