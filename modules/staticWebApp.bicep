/// Parameters ///

@description('Required. The name of the Static Web App.')
@minLength(1)
@maxLength(40)
param name string

@allowed([
  'Free'
  'Standard'
])
@description('Optional. The SKU (pricing tier) for the Static Web App.')
param sku string = 'Free'

@description('Optional. False if config file is locked for this static web app; otherwise, true.')
param allowConfigFileUpdates bool = true

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Repository branch (for GitHub integration).')
param branch string = 'main'

@description('Repository URL (GitHub). Example: https://github.com/username/repo')
param repositoryUrl string

/// Resource ///

resource staticWebApp 'Microsoft.Web/staticSites@2024-04-01' = {
  name: name
  location: location
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    allowConfigFileUpdates: allowConfigFileUpdates
    buildProperties: {
      appLocation: '/demo-project'        // folder with your app source (React/Vue/etc.)
      outputLocation: 'build' // where your app is built (e.g. npm run build)
    }
  }
}



/// Outputs ///

@description('The resource ID of the Static Web App.')
output staticWebAppId string = staticWebApp.id

@description('The default hostname of the Static Web App.')
output staticWebAppDefaultHostname string = staticWebApp.properties.defaultHostname
