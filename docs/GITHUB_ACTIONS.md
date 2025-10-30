# GitHub Actions CI/CD Documentation

This document explains the automated deployment pipeline for the Azure Bicep infrastructure using GitHub Actions.

## 🔄 Workflow Overview

The deployment workflow (`.github/workflows/deploy_bicep.yml`) provides automated infrastructure deployment with the following features:

- **Automated Triggers**: Deploys on infrastructure changes or manual trigger
- **Secure Authentication**: Uses Azure Service Principal stored in GitHub Secrets
- **Two-Stage Deployment**: Main infrastructure first, then RBAC roles
- **Resource Management**: Handles resource group creation and deployment tracking

## 🎯 Workflow Triggers

### Automatic Triggers
The workflow runs automatically when:
```yaml
on:
  push:
    branches:
      - main
    paths:
      - 'modules/**'        # Any module changes
      - 'main.bicep'        # Main template changes
      - 'main.bicepparam'   # Parameter changes
      - 'roles/**'          # RBAC changes
      - '.github/workflows/deploy_bicep.yml' # Workflow changes
```

### Manual Trigger
```yaml
workflow_dispatch: {}  # Enables manual workflow execution
```

## 🔧 Workflow Steps

### 1. Repository Checkout
```yaml
- name: Checkout repository
  uses: actions/checkout@v3
```

### 2. Azure Authentication
```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

### 3. Resource Discovery
```yaml
- name: List resources in resource group
  id: list_resources
  run: |
    RESOURCE_GROUP="rg-taskGen-dev-weu"
    RESOURCES=$(az resource list --resource-group $RESOURCE_GROUP --query "[].id" -o tsv | tr '\n' ',' | sed 's/,$//')
    echo "resources=$RESOURCES" >> $GITHUB_OUTPUT
```

### 4. Main Infrastructure Deployment
```yaml
- name: Deploy main Bicep (complete mode)
  run: |
    RESOURCE_GROUP="rg-taskGen-dev-weu"
    LOCATION="westeurope"
    TEMPLATE_FILE="main.bicep"
    DEPLOYMENT_NAME="main-$(date +%s)"

    az group create --name $RESOURCE_GROUP --location $LOCATION

    az deployment group create \
      --name $DEPLOYMENT_NAME \
      --resource-group $RESOURCE_GROUP \
      --template-file $TEMPLATE_FILE \
      --parameters main.bicepparam \
      --parameters \
        jwtSecret="${{ secrets.JWT_SECRET }}" \
        ddimitrPass="${{ secrets.ddimitr_dummy_password }}" \
        helloPass="${{ secrets.hello_dummy_password }}"
```

### 5. RBAC Role Deployment
```yaml
- name: Deploy roles Bicep
  run: |
    RESOURCE_GROUP="rg-taskGen-dev-weu"
    TEMPLATE_FILE="roles/roles.bicep"
    PARAMS_FILE="roles/roles.bicepparam"
    DEPLOYMENT_NAME="roles-$(date +%s)"

    az deployment group create \
      --name $DEPLOYMENT_NAME \
      --resource-group $RESOURCE_GROUP \
      --template-file $TEMPLATE_FILE \
      --parameters $PARAMS_FILE
```

## 🔐 Required GitHub Secrets

### Azure Service Principal (`AZURE_CREDENTIALS`)
Create an Azure AD application and service principal with the following permissions:

```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/{subscription-id} --sdk-auth

# Additional role for RBAC assignments
az role assignment create --assignee {service-principal-id} --role "User Access Administrator" --scope /subscriptions/{subscription-id}
```

The output should be stored as `AZURE_CREDENTIALS` secret:
```json
{
  "clientId": "xxxx-xxxx-xxxx-xxxx",
  "clientSecret": "xxxx-xxxx-xxxx-xxxx",
  "subscriptionId": "xxxx-xxxx-xxxx-xxxx",
  "tenantId": "xxxx-xxxx-xxxx-xxxx"
}
```

### Application Secrets
```
JWT_SECRET              = "your-jwt-signing-key"
ddimitr_dummy_password  = "password-for-ddimitr-user"
hello_dummy_password    = "password-for-hello-user"
```

## 🎯 Target Environment

The workflow deploys to a specific environment:
- **Resource Group**: `rg-taskGen-dev-weu`
- **Location**: `westeurope`
- **Environment**: Development

### Resource Naming Pattern
All resources follow the naming convention from `main.bicepparam`:
- App Service: `app-taskgen-dev`
- Key Vault: `kv-taskgen-dev`
- Storage Account: `sttaskgendev` + unique suffix
- Log Analytics: `law-taskgen-dev`
- Virtual Network: `vnet-taskgen-dev`

## 🔍 Monitoring Deployment

### GitHub Actions UI
1. Navigate to your repository
2. Click **Actions** tab
3. View workflow runs and logs

### Deployment Tracking
Each deployment gets a unique name with timestamp:
```bash
DEPLOYMENT_NAME="main-$(date +%s)"
```

### Azure Portal Monitoring
- Check **Resource Group** deployments in Azure Portal
- Review **Activity Log** for deployment details
- Monitor **Log Analytics** for application logs

## 🛠️ Customization Options

### Changing Target Environment

To deploy to a different environment, modify these variables in the workflow:

```yaml
# In deploy_bicep.yml
RESOURCE_GROUP="rg-taskgen-prod-weu"  # Change environment
LOCATION="northeurope"                # Change region
```

And update corresponding parameters in `main.bicepparam`:
```bicep-params
param environment = 'prod'           # Change from 'dev'
param location = 'northeurope'       # Match workflow location
```

### Adding Environments

For multiple environments, create separate workflows:
- `.github/workflows/deploy_dev.yml`
- `.github/workflows/deploy_prod.yml`

Or use environment-specific parameter files:
- `main.dev.bicepparam`
- `main.prod.bicepparam`

### Branch-Based Deployment

```yaml
on:
  push:
    branches:
      - main        # Deploy to production
      - develop     # Deploy to development
```

## 🚨 Troubleshooting

### Common Issues

#### Authentication Failures
```
Error: Azure login failed
```
**Solution**: Verify `AZURE_CREDENTIALS` secret format and service principal permissions.

#### Resource Group Access
```
Error: The client does not have authorization to perform action
```
**Solution**: Ensure service principal has **Contributor** role on subscription or resource group.

#### Secret Access Issues
```
Error: Secret not found
```
**Solution**: Verify all required secrets are configured in GitHub repository settings.

#### Deployment Conflicts
```
Error: Another deployment is in progress
```
**Solution**: Wait for current deployment to complete or cancel it in Azure Portal.

### Debugging Steps

1. **Check Workflow Logs**
   - Go to Actions tab in GitHub
   - Click on failed workflow run
   - Expand failed step to see detailed logs

2. **Verify Azure Permissions**
   ```bash
   # Test service principal login locally
   az login --service-principal -u {client-id} -p {client-secret} --tenant {tenant-id}
   az account show
   ```

3. **Validate Templates Locally**
   ```bash
   # Test Bicep compilation
   az bicep build --file main.bicep
   
   # Validate deployment
   az deployment group validate --resource-group "test-rg" --template-file main.bicep --parameters main.bicepparam
   ```

## 🔄 Workflow Optimization

### Caching Dependencies
```yaml
- name: Cache Bicep modules
  uses: actions/cache@v3
  with:
    path: ~/.bicep
    key: ${{ runner.os }}-bicep-${{ hashFiles('**/*.bicep') }}
```

### Parallel Deployments
For independent resources, consider parallel deployment:
```yaml
strategy:
  matrix:
    component: [networking, storage, compute]
```

### Deployment Approvals
For production deployments, add manual approval:
```yaml
environment:
  name: production
  url: ${{ steps.deploy.outputs.webapp-url }}
```

## 📊 Success Metrics

### Deployment Success Indicators
- ✅ All workflow steps complete successfully
- ✅ Azure resources created/updated as expected
- ✅ No errors in deployment logs
- ✅ Application responds correctly
- ✅ Monitoring data flowing to Log Analytics

### Performance Metrics
- **Deployment Time**: Typically 5-10 minutes
- **Success Rate**: Target >95% successful deployments
- **Mean Time to Recovery**: <30 minutes for rollback

## 🎯 Demo Project Context

This GitHub Actions workflow demonstrates:
- **Modern CI/CD practices** for infrastructure
- **Secure credential management** with GitHub Secrets
- **Automated testing and deployment** of Bicep templates
- **Multi-stage deployment** patterns
- **Infrastructure monitoring** and logging integration

Perfect for showcasing DevOps capabilities and Azure infrastructure automation!