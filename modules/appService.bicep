@description('Name of the App Service Plan')
param appServicePlanName string

@description('Name of the Web App')
param webAppName string

@description('Location of resources')
param location string

@description('Container image to deploy (for example, mcr.microsoft.com/azuredocs/aci-helloworld:latest)')
param containerImage string = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'

@description('App Service Plan SKU (B1 = Basic, S1 = Standard, P1V2 = Premium)')
param skuName string = 'B1'

@description('Tags to apply to resources')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    tier: 'Basic'
    size: skuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true // Linux plan
  }
  tags: tags
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerImage}'
      alwaysOn: true
    }
    httpsOnly: true
  }
  tags: tags
}

output webAppUrl string = 'https://${webApp.name}.azurewebsites.net'
