# Manual Deployment Guide

This guide provides step-by-step instructions for **manually** deploying the Azure infrastructure using Bicep templates.

> **Note**: This demo project primarily uses **GitHub Actions** for automated deployment. See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for the recommended CI/CD approach. Use this manual guide for local testing or when GitHub Actions is not available.

## 📋 Prerequisites

### Software Requirements
- **Azure CLI**: Version 2.50.0 or later
- **PowerShell**: 5.1 or later (Windows) or PowerShell Core 7+ (cross-platform)
- **Bicep CLI**: Latest version (automatically installed with Azure CLI)

### Azure Requirements
- Azure subscription with **Contributor** or **Owner** permissions
- Permission to create **Resource Groups**
- Permission to create **Role Assignments** (for RBAC)

### Verification Commands
```powershell
# Check Azure CLI version
az --version

# Check Bicep version
az bicep version

# Verify login and subscription
az account show
```

## 🔧 Configuration

### 1. Parameter Configuration

Edit the `main.bicepparam` file to customize your deployment:

```bicep-params
// Core settings
param workloadName = 'taskgen'        # Change to your workload name
param location = 'westeurope'         # Change to your preferred region
param environment = 'dev'             # dev, test, or prod

// Secrets (REQUIRED - provide actual values)
param jwtsecret = 'your-jwt-secret-here'
param ddimitrpass = 'your-ddimitr-password'
param hellopass = 'your-hello-password'
```

### 2. Environment-Specific Settings

For different environments, modify these parameters:

#### Development Environment
```bicep-params
param environment = 'dev'
param appServiceSkuName = 'B1'
param logAnalyticsRetentionInDays = 30
param keyVaultPurgeProtectionEnabled = false
```

#### Production Environment
```bicep-params
param environment = 'prod'
param appServiceSkuName = 'P1V2'
param logAnalyticsRetentionInDays = 90
param keyVaultPurgeProtectionEnabled = true
```

## 🚀 Deployment Steps

### Step 1: Login and Set Context

```powershell
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set the target subscription
az account set --subscription "your-subscription-id-or-name"

# Verify context
az account show --query "{subscriptionId:id, subscriptionName:name, tenantId:tenantId}"
```

### Step 2: Create Resource Group

```powershell
# Create resource group (adjust name and location as needed)
az group create `
  --name "rg-taskgen-dev" `
  --location "westeurope" `
  --tags "workload=taskgen" "environment=dev"
```

### Step 3: Validate Template

```powershell
# Validate the Bicep template
az deployment group validate `
  --resource-group "rg-taskgen-dev" `
  --template-file "main.bicep" `
  --parameters "main.bicepparam"
```

### Step 4: Preview Changes (What-If)

```powershell
# Preview what resources will be created
az deployment group what-if `
  --resource-group "rg-taskgen-dev" `
  --template-file "main.bicep" `
  --parameters "main.bicepparam"
```

### Step 5: Deploy Infrastructure

```powershell
# Deploy the infrastructure
az deployment group create `
  --resource-group "rg-taskgen-dev" `
  --template-file "main.bicep" `
  --parameters "main.bicepparam" `
  --name "infrastructure-deployment" `
  --verbose
```

### Step 6: Deploy RBAC Roles (Optional)

If you need to assign additional roles:

```powershell
# Deploy role assignments
az deployment group create `
  --resource-group "rg-taskgen-dev" `
  --template-file "roles/roles.bicep" `
  --parameters "roles/roles.bicepparam" `
  --name "rbac-deployment"
```

## 📊 Monitoring Deployment

### Check Deployment Status

```powershell
# List deployments
az deployment group list `
  --resource-group "rg-taskgen-dev" `
  --output table

# Get deployment details
az deployment group show `
  --resource-group "rg-taskgen-dev" `
  --name "infrastructure-deployment"
```

### View Deployment Outputs

```powershell
# Get deployment outputs
az deployment group show `
  --resource-group "rg-taskgen-dev" `
  --name "infrastructure-deployment" `
  --query "properties.outputs"
```

## 🔧 Post-Deployment Configuration

### 1. Verify App Service

```powershell
# Get App Service URL
$appName = "app-taskgen-dev"
$resourceGroup = "rg-taskgen-dev"
az webapp show --name $appName --resource-group $resourceGroup --query "defaultHostName" --output tsv
```

### 2. Test Key Vault Access

```powershell
# List Key Vault secrets (requires appropriate permissions)
$kvName = "kv-taskgen-dev"
az keyvault secret list --vault-name $kvName --output table
```

### 3. Verify Private Endpoints

```powershell
# Check private endpoint connections
az network private-endpoint list --resource-group "rg-taskgen-dev" --output table
```

## 🔄 Updates and Maintenance

### Updating Parameters

1. Modify `main.bicepparam` file
2. Run the deployment command again (Bicep handles incremental updates)

### Adding New Resources

1. Create or modify modules in the `modules/` directory
2. Reference new modules in `main.bicep`
3. Add required parameters to `main.bicepparam`
4. Deploy using the same command

### Scaling Resources

```powershell
# Update App Service plan SKU
az appservice plan update `
  --name "plan-taskgen-dev" `
  --resource-group "rg-taskgen-dev" `
  --sku "P1V2"
```

## 🚨 Rollback Procedures

### Emergency Rollback

```powershell
# Delete the entire resource group (DESTRUCTIVE!)
az group delete --name "rg-taskgen-dev" --yes --no-wait
```

### Selective Resource Rollback

```powershell
# Delete specific resources
az resource delete --ids "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.Web/sites/app-taskgen-dev"
```

## 📝 Deployment Checklist

- [ ] Azure CLI installed and updated
- [ ] Logged into correct Azure subscription
- [ ] Resource group created
- [ ] Parameters configured in `main.bicepparam`
- [ ] Secret values provided
- [ ] Template validated successfully
- [ ] What-if preview reviewed
- [ ] Backup strategy confirmed (if updating existing resources)
- [ ] Deployment completed successfully
- [ ] Post-deployment verification completed
- [ ] Documentation updated

## 🔍 Troubleshooting

For common deployment issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## 📞 Support

If you encounter issues:
1. Check the [troubleshooting guide](TROUBLESHOOTING.md)
2. Review Azure Activity Log for error details
3. Validate your parameters and permissions
4. Check Azure service health status