# Troubleshooting Guide

This guide helps resolve common issues encountered during deployment and operation of the Azure Bicep infrastructure.

## 🔍 Common Deployment Issues

### 1. Template Validation Errors

#### Error: "Parameter 'location' must be specified"
**Cause**: Missing required parameter in the parameter file.
```
The parameter 'location' was not provided in main.bicepparam
```

**Solution**:
```bicep-params
# Add to main.bicepparam
param location = 'westeurope'  # or your preferred region
```

#### Error: "Invalid template syntax"
**Cause**: Bicep syntax errors in template files.
```
ERROR: Invalid template: template parse errors
```

**Solution**:
```powershell
# Validate template syntax
az bicep build --file main.bicep
```

### 2. Resource Naming Conflicts

#### Error: "Storage account name already exists"
**Cause**: Storage account names must be globally unique.
```
ERROR: The storage account name 'sttaskgendev' is already taken
```

**Solution**:
```bicep
# In modules/storageAccount.bicep, use uniqueString function
param storageAccountName string = 'st${workloadName}${environment}${uniqueString(resourceGroup().id)}'
```

#### Error: "Key Vault name not available"
**Cause**: Key Vault names must be globally unique and may be in soft-deleted state.
```
ERROR: Vault name 'kv-taskgen-dev' is not available
```

**Solutions**:
```powershell
# Option 1: Check for soft-deleted vault
az keyvault list-deleted --query "[?name=='kv-taskgen-dev']"

# Option 2: Purge soft-deleted vault (if you own it)
az keyvault purge --name "kv-taskgen-dev" --location "westeurope"

# Option 3: Use different name
param keyVaultName = 'kv-taskgen-dev-${uniqueString(resourceGroup().id)}'
```

### 3. Permission Issues

#### Error: "Authorization failed"
**Cause**: Insufficient permissions to create resources or assign roles.
```
ERROR: The client does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write'
```

**Solutions**:
```powershell
# Check current role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv) --all

# Required roles for deployment:
# - Contributor: For creating resources
# - User Access Administrator: For role assignments
# - Key Vault Administrator: For Key Vault operations
```

### 4. Network Configuration Issues

#### Error: "Subnet delegation conflict"
**Cause**: Subnet already delegated to another service.
```
ERROR: Subnet 'appservice' delegation to 'Microsoft.Web/serverFarms' failed
```

**Solution**:
```powershell
# Check existing delegations
az network vnet subnet show --resource-group "rg-taskgen-dev" --vnet-name "vnet-taskgen-dev" --name "appservice" --query "delegations"

# Remove conflicting delegation if needed
az network vnet subnet update --resource-group "rg-taskgen-dev" --vnet-name "vnet-taskgen-dev" --name "appservice" --remove delegations
```

#### Error: "Private endpoint connection failed"
**Cause**: Target resource doesn't support private endpoints or incorrect group ID.
```
ERROR: Private link service connection to resource failed
```

**Solution**:
```bicep
# Ensure correct group IDs for each service:
# Key Vault: ['vault']
# Storage Account: ['table', 'blob', 'file', 'queue']
# SQL Database: ['sqlServer']
```

## 🔧 Runtime Issues

### 1. App Service Connection Problems

#### Issue: "Cannot connect to Key Vault"
**Symptoms**: App Service cannot retrieve secrets from Key Vault.

**Diagnosis**:
```powershell
# Check App Service managed identity
az webapp identity show --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"

# Check Key Vault RBAC assignments
az role assignment list --scope "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.KeyVault/vaults/kv-taskgen-dev"
```

**Solutions**:
```powershell
# Assign Key Vault Secrets User role to App Service identity
$appIdentity = az webapp identity show --name "app-taskgen-dev" --resource-group "rg-taskgen-dev" --query principalId -o tsv
$kvScope = az keyvault show --name "kv-taskgen-dev" --query id -o tsv

az role assignment create --assignee $appIdentity --role "Key Vault Secrets User" --scope $kvScope
```

#### Issue: "Cannot connect to Storage Account"
**Symptoms**: App Service cannot access table storage.

**Diagnosis**:
```powershell
# Check private endpoint status
az network private-endpoint show --name "pe-taskgen-dev-table" --resource-group "rg-taskgen-dev" --query "connectionState"

# Test DNS resolution from App Service
az webapp ssh --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"
# Inside App Service container:
nslookup sttaskgendev.table.core.windows.net
```

**Solutions**:
```powershell
# Verify private DNS zone configuration
az network private-dns zone list --resource-group "rg-taskgen-dev"

# Check VNet link to private DNS zone
az network private-dns link vnet list --resource-group "rg-taskgen-dev" --zone-name "privatelink.table.core.windows.net"
```

### 2. Monitoring and Logging Issues

#### Issue: "No logs appearing in Log Analytics"
**Symptoms**: Diagnostic settings configured but no data in Log Analytics.

**Diagnosis**:
```powershell
# Check diagnostic settings
az monitor diagnostic-settings list --resource "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.Web/sites/app-taskgen-dev"

# Verify Log Analytics workspace
az monitor log-analytics workspace show --resource-group "rg-taskgen-dev" --workspace-name "law-taskgen-dev"
```

**Solutions**:
```powershell
# Recreate diagnostic settings
az monitor diagnostic-settings create --name "app-service-diagnostics" --resource "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.Web/sites/app-taskgen-dev" --workspace "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.OperationalInsights/workspaces/law-taskgen-dev" --logs '[{"category":"AppServiceHTTPLogs","enabled":true}]' --metrics '[{"category":"AllMetrics","enabled":true}]'
```

#### Issue: "High Log Analytics costs"
**Symptoms**: Unexpected charges for log ingestion.

**Diagnosis**:
```powershell
# Check data ingestion volume
az monitor log-analytics workspace show --resource-group "rg-taskgen-dev" --workspace-name "law-taskgen-dev" --query "retentionInDays"

# Query data volume (run in Log Analytics)
Usage
| where TimeGenerated > ago(7d)
| summarize DataVolumeMB = sum(Quantity) / 1024 by DataType
| sort by DataVolumeMB desc
```

**Solutions**:
- Adjust retention period
- Filter unnecessary log categories
- Implement log sampling for high-volume applications

## 🚨 Security Issues

### 1. Key Vault Access Problems

#### Issue: "Access denied to Key Vault"
**Symptoms**: Applications or users cannot access Key Vault secrets.

**Diagnosis**:
```powershell
# Check current user permissions
az keyvault secret list --vault-name "kv-taskgen-dev"

# Check RBAC assignments
az role assignment list --scope "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.KeyVault/vaults/kv-taskgen-dev"
```

**Solutions**:
```powershell
# Assign appropriate role to user
az role assignment create --assignee "user@company.com" --role "Key Vault Secrets Officer" --scope "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.KeyVault/vaults/kv-taskgen-dev"
```

### 2. Network Security Issues

#### Issue: "Cannot access resources from internet"
**Symptoms**: Expected behavior - resources configured with private endpoints only.

**Verification**:
```powershell
# This should fail (expected):
curl https://kv-taskgen-dev.vault.azure.net/

# This should work from App Service:
az webapp ssh --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"
curl https://kv-taskgen-dev.vault.azure.net/
```

**Note**: This is expected behavior for private endpoints. Access should only work from within the VNet.

## 🔄 Recovery Procedures

### 1. Failed Deployment Recovery

#### Scenario: Deployment fails partially
**Steps**:
1. **Identify failed resources**:
   ```powershell
   az deployment group show --resource-group "rg-taskgen-dev" --name "infrastructure-deployment" --query "properties.error"
   ```

2. **Clean up failed resources**:
   ```powershell
   # Delete specific failed resource
   az resource delete --ids "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.Web/sites/app-taskgen-dev"
   ```

3. **Redeploy**:
   ```powershell
   az deployment group create --resource-group "rg-taskgen-dev" --template-file "main.bicep" --parameters "main.bicepparam"
   ```

### 2. Complete Environment Recovery

#### Scenario: Need to recreate entire environment
**Steps**:
1. **Backup secrets** (if Key Vault accessible):
   ```powershell
   az keyvault secret backup --vault-name "kv-taskgen-dev" --name "jwtsecret" --file "jwtsecret.backup"
   ```

2. **Delete resource group**:
   ```powershell
   az group delete --name "rg-taskgen-dev" --yes --no-wait
   ```

3. **Recreate from templates**:
   ```powershell
   az group create --name "rg-taskgen-dev" --location "westeurope"
   az deployment group create --resource-group "rg-taskgen-dev" --template-file "main.bicep" --parameters "main.bicepparam"
   ```

## 🛠️ Diagnostic Commands

### General Diagnostics

```powershell
# Check Azure CLI version and login status
az --version
az account show

# List all resources in resource group
az resource list --resource-group "rg-taskgen-dev" --output table

# Check deployment history
az deployment group list --resource-group "rg-taskgen-dev" --output table
```

### Network Diagnostics

```powershell
# Check VNet configuration
az network vnet show --resource-group "rg-taskgen-dev" --name "vnet-taskgen-dev"

# Check private endpoint status
az network private-endpoint list --resource-group "rg-taskgen-dev" --output table

# Check DNS zones
az network private-dns zone list --resource-group "rg-taskgen-dev" --output table
```

### Application Diagnostics

```powershell
# Check App Service status
az webapp show --name "app-taskgen-dev" --resource-group "rg-taskgen-dev" --query "{state:state,defaultHostName:defaultHostName}"

# Check App Service logs
az webapp log tail --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"

# Check managed identity
az webapp identity show --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"
```

## 📞 Getting Help

### Azure Support Channels

1. **Azure Documentation**: https://docs.microsoft.com/azure/
2. **Azure Community**: https://techcommunity.microsoft.com/
3. **Stack Overflow**: Tag questions with `azure`, `bicep`, `azure-resource-manager`
4. **GitHub Issues**: Azure Bicep repository

### Escalation Process

1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review Azure Activity Log for detailed error messages
3. **Level 3**: Create Azure Support ticket (if you have support plan)
4. **Level 4**: Engage Microsoft FastTrack (if available)

### Information to Gather

When seeking help, provide:
- Subscription ID
- Resource group name
- Deployment name and timestamp
- Error messages (full text)
- Steps to reproduce
- Expected vs. actual behavior

## 📝 Prevention Best Practices

### Pre-Deployment Checks

- [ ] Validate all templates with `az bicep build`
- [ ] Use `what-if` deployment to preview changes
- [ ] Verify naming conventions and uniqueness
- [ ] Check quota and limits for target region
- [ ] Confirm permissions for all required operations

### Monitoring Setup

- [ ] Configure alerts for critical resources
- [ ] Set up budget alerts for cost management
- [ ] Enable diagnostic settings for all supported resources
- [ ] Create operational runbooks for common issues
- [ ] Document known issues and workarounds