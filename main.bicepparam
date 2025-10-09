using 'main.bicep' 

param workload = 'taskGen'
param location = 'westeurope'
param branch = 'main'
param allowConfigUpdates = true
param repositoryUrl = 'https://github.com/ddimitrakopoulos/taskGen-front'
param web_app_sku = 'Free'
param environment = 'dev'
param storageAccountName = 'storageacc${toLower(workload)}'  
param staticWebAppName = 'static-wapp-${workload}'
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
param app_service_plan_name = 'asp-${workload}-${environment}'
param web_app_name = 'app-${workload}-${environment}'
param app_service_container_image = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
param vnet_name = 'vnet-${workload}-${environment}'

