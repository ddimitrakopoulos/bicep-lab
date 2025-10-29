using 'roles.bicep'

param workload = 'taskGen'
param environment = 'dev'
param keyVaultName = 'kv-${workload}-2'
param webAppName = 'app-service-${workload}-${environment}'
param storageAccountName = 'storageacctabletaskgen'
