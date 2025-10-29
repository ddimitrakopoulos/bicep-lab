//============================================================================
// PARAMETERS
//============================================================================

@description('Name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('Location where the Log Analytics workspace will be deployed')
param location string

@description('SKU for the Log Analytics workspace')
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param skuName string

@description('Number of days to retain data in the Log Analytics workspace')
param retentionInDays int

@description('Enable diagnostic settings for the Log Analytics workspace')
param diagnosticsEnabled bool

//============================================================================
// RESOURCES
//============================================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
  }
}

resource logAnalyticsWorkspaceDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (diagnosticsEnabled) {
  name: '${logAnalyticsWorkspaceName}-diagnostics'
  scope: logAnalyticsWorkspace
  properties: {
    workspaceId: logAnalyticsWorkspace.id
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

//============================================================================
// OUTPUTS
//============================================================================

output log_workspace_id string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
