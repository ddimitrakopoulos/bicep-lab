@description('Name of the App Service')
param appServiceName string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Location for resources')
param location string

@description('SKU for the App Service Plan')
param skuName string = 'B1'

@description('Node.js runtime version')
param nodeVersion string = '~20'

@description('Subnet ID for VNet integration')
param subnetId string

// Create the App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
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
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}'
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

// Outputs (no URL or source control info)
output appServiceId string = webApp.id
output appServicePlanId string = appServicePlan.id
output appServicePrincipalId string = webApp.identity.principalId
