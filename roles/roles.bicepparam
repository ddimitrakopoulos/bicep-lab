using 'roles.bicep'

//============================================================================
// RESOURCE NAMES
// Note: These should match the actual resource names created by main.bicep
//============================================================================

// Key Vault name (must match main deployment output)
param keyVaultName = 'kv-taskgen-dev'

// App Service name (must match main deployment output)
param appServiceName = 'app-taskgen-dev'

// Storage Account name (must match main deployment output)
param storageAccountName = 'sttaskgendev'
