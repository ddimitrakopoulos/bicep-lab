using 'main.bicep'

//============================================================================
// CORE DEPLOYMENT PARAMETERS
//============================================================================
param workloadName = 'taskgen'
param location = 'westeurope'
param environment = 'dev'

//============================================================================
// LOG ANALYTICS PARAMETERS
//============================================================================
param logAnalyticsWorkspaceName = 'law-${workloadName}-${environment}'
param logAnalyticsWorkspaceSku = 'PerGB2018'
param logAnalyticsRetentionInDays = 30
param diagnosticsEnabled = true

//============================================================================
// STORAGE ACCOUNT PARAMETERS
//============================================================================
param storageAccountName = 'st${workloadName}${environment}' // Actual name will include uniqueString at deployment
param storageTableName = 'table${workloadName}${environment}'

//============================================================================
// KEY VAULT PARAMETERS
//============================================================================
param keyVaultName = 'kv-${workloadName}-${environment}'
param keyVaultSku = 'standard'
param keyVaultSoftDeleteEnabled = true
param keyVaultPurgeProtectionEnabled = false
param keyVaultEnabledForTemplateDeployment = true

//============================================================================
// NETWORK PARAMETERS
//============================================================================
param virtualNetworkName = 'vnet-${workloadName}-${environment}'
param virtualNetworkAddressPrefix = '10.0.0.0/16'

//============================================================================
// PRIVATE ENDPOINT PARAMETERS
//============================================================================
param storageTablePrivateEndpointName = 'pe-${workloadName}-${environment}-table'
param keyVaultPrivateEndpointName = 'pe-${workloadName}-${environment}-kv'

//============================================================================
// APP SERVICE PARAMETERS
//============================================================================
param appServiceName = 'app-${workloadName}-${environment}'
param appServicePlanName = 'plan-${workloadName}-${environment}'
param appServiceSkuName = 'B1'

//============================================================================
// SECRETS (Provide values at deployment time)
//============================================================================
param jwtsecret = ''
param ddimitrpass = ''
param hellopass = ''
