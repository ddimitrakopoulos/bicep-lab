# RBAC Roles Documentation

This directory contains Bicep templates for managing Role-Based Access Control (RBAC) assignments for the Azure infrastructure.

## 📁 Contents

- `roles.bicep` - Main template for role assignments
- `roles.bicepparam` - Parameter file with role assignment configurations

## 🎯 Purpose

The roles templates handle:
- **Service Principal Permissions** - Assign roles to App Service managed identity
- **User Access Control** - Grant appropriate permissions to users and groups
- **Cross-Resource Access** - Enable services to access each other securely
- **Least Privilege Principle** - Assign minimal required permissions

## 🔐 Role Assignments Overview

### App Service Managed Identity Roles

The App Service managed identity requires specific roles to access Azure resources:

| Target Resource | Role | Purpose |
|----------------|------|---------|
| Key Vault | Key Vault Secrets User | Read application secrets |
| Storage Account | Storage Table Data Contributor | Read/write table data |
| Log Analytics | Monitoring Contributor | Send custom metrics (optional) |

### User/Group Roles

For operational access and management:

| Role | Scope | Purpose |
|------|-------|---------|
| Key Vault Administrator | Key Vault | Manage secrets and access policies |
| Storage Account Contributor | Storage Account | Manage storage configuration |
| App Service Contributor | App Service | Deploy and configure applications |
| Log Analytics Contributor | Log Analytics Workspace | Configure monitoring and queries |

## 📋 Template Structure

### roles.bicep

```bicep
targetScope = 'resourceGroup'

//============================================================================
// PARAMETERS
//============================================================================

@description('Principal ID of the App Service managed identity')
param appServicePrincipalId string

@description('Resource ID of the Key Vault')
param keyVaultResourceId string

@description('Resource ID of the Storage Account')
param storageAccountResourceId string

@description('Principal ID of the user/group to grant access')
param userPrincipalId string = ''

//============================================================================
// ROLE ASSIGNMENTS
//============================================================================

// App Service → Key Vault (Secrets User)
resource appServiceKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appServicePrincipalId, keyVaultResourceId, 'Key Vault Secrets User')
  scope: keyVaultResourceId
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// App Service → Storage Account (Table Data Contributor)
resource appServiceStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appServicePrincipalId, storageAccountResourceId, 'Storage Table Data Contributor')
  scope: storageAccountResourceId
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3') // Storage Table Data Contributor
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
```

## 🚀 Deployment

### Prerequisites

1. **Main infrastructure deployed** - The core resources must exist first
2. **Managed identity created** - App Service managed identity must be enabled
3. **Appropriate permissions** - User must have User Access Administrator role

### Deployment Steps

```powershell
# 1. Get the App Service managed identity principal ID
$appServicePrincipalId = az webapp identity show --name "app-taskgen-dev" --resource-group "rg-taskgen-dev" --query principalId -o tsv

# 2. Update roles.bicepparam with the principal ID
# Edit the file to include the correct principal ID

# 3. Deploy role assignments
az deployment group create `
  --resource-group "rg-taskgen-dev" `
  --template-file "roles/roles.bicep" `
  --parameters "roles/roles.bicepparam" `
  --name "rbac-deployment"
```

### Automated Deployment

You can also deploy roles as part of the main deployment by including the module:

```bicep
// In main.bicep, after the App Service module
module rolesModule 'roles/roles.bicep' = {
  params: {
    appServicePrincipalId: appServiceModule.outputs.appServicePrincipalId
    keyVaultResourceId: keyVaultModule.outputs.keyvaultId
    storageAccountResourceId: storageAccountModule.outputs.storageAccountId
  }
  dependsOn: [
    appServiceModule
    keyVaultModule
    storageAccountModule
  ]
}
```

## 🔍 Built-in Role Definitions

### Key Vault Roles

| Role Name | Role ID | Permissions |
|-----------|---------|-------------|
| Key Vault Administrator | `00482a5a-887f-4fb3-b363-3b7fe8e74483` | Full access to Key Vault |
| Key Vault Secrets Officer | `b86a8fe4-44ce-4948-aee5-eccb2c155cd7` | Manage secrets |
| Key Vault Secrets User | `4633458b-17de-408a-b874-0445c86b69e6` | Read secrets |

### Storage Account Roles

| Role Name | Role ID | Permissions |
|-----------|---------|-------------|
| Storage Account Contributor | `17d1049b-9a84-46fb-8f53-869881c3d3ab` | Manage storage account |
| Storage Table Data Contributor | `0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3` | Read/write table data |
| Storage Table Data Reader | `76199698-9eea-4c19-bc75-cec21354c6b9` | Read table data |

### App Service Roles

| Role Name | Role ID | Permissions |
|-----------|---------|-------------|
| App Service Contributor | `de139f84-1756-47ae-9be6-808fbbe84772` | Manage App Service |
| Website Contributor | `de139f84-1756-47ae-9be6-808fbbe84772` | Deploy applications |

## 🛠️ Custom Role Examples

### Application-Specific Custom Role

```bicep
// Custom role for application operations
resource customAppRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid('custom-app-role', resourceGroup().id)
  properties: {
    roleName: 'TaskGen Application Operator'
    description: 'Custom role for TaskGen application operations'
    assignableScopes: [
      resourceGroup().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.Web/sites/read'
          'Microsoft.Web/sites/config/read'
          'Microsoft.KeyVault/vaults/secrets/getSecret/action'
          'Microsoft.Storage/storageAccounts/tableServices/tables/read'
          'Microsoft.Storage/storageAccounts/tableServices/tables/write'
        ]
        notActions: []
        dataActions: [
          'Microsoft.Storage/storageAccounts/tableServices/containers/tables/entities/read'
          'Microsoft.Storage/storageAccounts/tableServices/containers/tables/entities/write'
        ]
        notDataActions: []
      }
    ]
  }
}
```

## 🔧 Troubleshooting RBAC

### Common Issues

#### "Insufficient privileges to complete the operation"
**Cause**: Current user lacks User Access Administrator role.

**Solution**:
```powershell
# Check current role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv) --all --output table

# Assign User Access Administrator role (requires subscription owner)
az role assignment create --assignee "user@company.com" --role "User Access Administrator" --scope "/subscriptions/{subscription-id}"
```

#### "Role assignment already exists"
**Cause**: Attempting to create duplicate role assignment.

**Solution**:
```powershell
# List existing role assignments
az role assignment list --scope "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.KeyVault/vaults/kv-taskgen-dev"

# Delete existing assignment if needed
az role assignment delete --assignee {principal-id} --role "Key Vault Secrets User" --scope {resource-id}
```

#### "Principal not found"
**Cause**: Managed identity doesn't exist or wrong principal ID.

**Solution**:
```powershell
# Verify App Service managed identity exists
az webapp identity show --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"

# If not enabled, enable it
az webapp identity assign --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"
```

### Validation Commands

```powershell
# List all role assignments in resource group
az role assignment list --resource-group "rg-taskgen-dev" --output table

# Check specific resource permissions
az role assignment list --scope "/subscriptions/{subscription-id}/resourceGroups/rg-taskgen-dev/providers/Microsoft.KeyVault/vaults/kv-taskgen-dev" --output table

# Test access from App Service
az webapp ssh --name "app-taskgen-dev" --resource-group "rg-taskgen-dev"
# Inside container, test Key Vault access with managed identity
```

## 📊 RBAC Best Practices

### Security Principles

1. **Least Privilege**: Grant minimal permissions required
2. **Separation of Duties**: Separate operational and administrative roles
3. **Regular Review**: Audit role assignments periodically
4. **Conditional Access**: Use Azure AD conditional access when possible
5. **Just-In-Time**: Use PIM (Privileged Identity Management) for admin roles

### Operational Guidelines

1. **Document Assignments**: Maintain clear documentation of who has what access
2. **Use Groups**: Assign roles to groups rather than individual users
3. **Monitor Access**: Set up alerts for privilege escalation
4. **Automated Cleanup**: Remove unused role assignments
5. **Emergency Access**: Maintain break-glass accounts

### Development vs. Production

#### Development Environment
- More permissive for developers
- Individual user assignments acceptable
- Shorter role assignment duration
- More extensive logging

#### Production Environment
- Restrictive permissions
- Group-based assignments only
- Just-in-time access where possible
- Comprehensive audit logging
- Change approval processes

## 📚 Additional Resources

- [Azure RBAC Documentation](https://docs.microsoft.com/azure/role-based-access-control/)
- [Azure Built-in Roles](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Custom Roles](https://docs.microsoft.com/azure/role-based-access-control/custom-roles)
- [Managed Identity Best Practices](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/managed-identities-best-practice-recommendations)