using 'main.bicep' 

param workload = 'taskGen'
param location = 'westeurope'
param branch = 'main'
param allowConfigUpdates = true
param repositoryUrl = 'https://github.com/ddimitrakopoulos/taskGen-front'
param web_app_sku = 'Free'
param environment = 'dev'
param storageAccountTableName = 'storageacctable${toLower(workload)}'  
param staticWebAppName = 'static-wapp-${workload}'
param storageAccountFunctionName = 'storageaccfun${toLower(workload)}'
param log_workspace_name = 'log-${workload}' 
param keyvault_name = 'kv-${workload}'
param table_name = 'table${workload}'
param log_workspace_sku = 'PerGB2018'
param retention_days = 30
param log_workspace_diagnostics_settings_enabled = true
param keyvault_sku_name = 'standard'
param keyvault_soft_delete_enabled = true
param keyvault_purge_protection_enabled = true  
param keyvault_enabled_for_template_deployment = false
param keyvault_diagnostics_settings_enabled = true
param function_name_crud = 'func-crud-${workload}'
param function_runtime_crud = 'node' // or 'dotnet' or 'python'
param function_name_login = 'func-login-${workload}'
param function_runtime_login = 'node' // or 'dotnet' or 'python'
