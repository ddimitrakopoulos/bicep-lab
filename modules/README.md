# Bicep Modules Documentation

This directory contains reusable Bicep modules for deploying Azure infrastructure components. Each module is designed to follow best practices and can be used independently or as part of the main template.

## 📁 Module Structure

Each module follows a consistent structure:
- **Parameters Section**: Input parameters with descriptions and types
- **Resources Section**: Azure resources to be deployed
- **Outputs Section**: Values returned for use by other modules

## 🧩 Available Modules

### 1. appService.bicep
**Purpose**: Deploy App Service and App Service Plan with VNet integration and monitoring.

**Resources Created**:
- App Service Plan
- App Service (Web App)
- Diagnostic Settings (optional)

**Key Features**:
- VNet integration support
- System-assigned managed identity
- Node.js runtime configuration
- HTTPS-only enforcement
- Comprehensive logging

**Parameters**:
- `appServiceName` - Name of the web application
- `appServicePlanName` - Name of the hosting plan
- `appServicePlanSkuName` - SKU for the hosting plan
- `location` - Deployment location
- `nodeJsVersion` - Node.js runtime version
- `subnetId` - Subnet for VNet integration
- `diagnosticsEnabled` - Enable diagnostic logging
- `logAnalyticsWorkspaceId` - Target workspace for logs

**Outputs**:
- `appServiceId` - Resource ID of the App Service
- `appServicePrincipalId` - Managed identity principal ID
- `appServiceName` - Name of the App Service

---

### 2. keyVault.bicep
**Purpose**: Deploy Key Vault with RBAC, private endpoint support, and security features.

**Resources Created**:
- Key Vault
- Diagnostic Settings (optional)

**Key Features**:
- RBAC-based access control
- Soft delete protection
- Purge protection (configurable)
- ARM template deployment access
- Comprehensive audit logging

**Parameters**:
- `keyVaultName` - Name of the Key Vault
- `location` - Deployment location
- `skuName` - Key Vault SKU (standard/premium)
- `softDeleteEnabled` - Enable soft delete
- `purgeProtectionEnabled` - Enable purge protection
- `enabledForTemplateDeployment` - Allow ARM template access
- `diagnosticsEnabled` - Enable diagnostic logging
- `logAnalyticsWorkspaceId` - Target workspace for logs

**Outputs**:
- `keyvaultId` - Resource ID of the Key Vault
- `keyvaultName` - Name of the Key Vault
- `keyvaultUri` - URI of the Key Vault

---

### 3. logAnalyticsWorkspace.bicep
**Purpose**: Deploy Log Analytics workspace for centralized logging and monitoring.

**Resources Created**:
- Log Analytics Workspace
- Diagnostic Settings (self-monitoring)

**Key Features**:
- Configurable data retention
- Multiple SKU options
- Self-monitoring capabilities
- Cost optimization settings

**Parameters**:
- `logAnalyticsWorkspaceName` - Name of the workspace
- `location` - Deployment location
- `skuName` - Pricing tier (PerGB2018, etc.)
- `retentionInDays` - Data retention period
- `diagnosticsEnabled` - Enable self-monitoring

**Outputs**:
- `log_workspace_id` - Resource ID of the workspace
- `log_workspace_name` - Name of the workspace
- `customerId` - Customer ID for API access

---

### 4. privateEndpoint.bicep
**Purpose**: Generic template for creating private endpoints for Azure PaaS services.

**Resources Created**:
- Private Endpoint

**Key Features**:
- Support for multiple service types
- Flexible group ID configuration
- Automatic connection approval
- Custom naming support

**Parameters**:
- `privateEndpointName` - Name of the private endpoint
- `targetResourceId` - Resource ID of target service
- `subnetId` - Subnet for private endpoint deployment
- `groupIds` - Array of group IDs for the service
- `location` - Deployment location

**Outputs**:
- `privateEndpointId` - Resource ID of the private endpoint
- `privateEndpointName` - Name of the private endpoint

**Supported Group IDs**:
- Key Vault: `['vault']`
- Storage Account: `['table']`, `['blob']`, `['file']`, `['queue']`
- SQL Database: `['sqlServer']`
- Cosmos DB: `['Sql']`, `['MongoDB']`

---

### 5. storageAccount.bicep
**Purpose**: Deploy secure Storage Account with private networking and monitoring.

**Resources Created**:
- Storage Account
- Diagnostic Settings (optional)

**Key Features**:
- Security-first configuration
- Private networking support
- Comprehensive logging
- Multiple service endpoints
- Configurable access controls

**Parameters**:
- `storageAccountName` - Name of the storage account
- `location` - Deployment location
- `tags` - Resource tags
- `allowBlobPublicAccess` - Allow public blob access
- `publicNetworkAccess` - Enable public network access
- `diagnosticsEnabled` - Enable diagnostic logging
- `logAnalyticsWorkspaceId` - Target workspace for logs

**Outputs**:
- `storageAccountId` - Resource ID of the storage account
- `storageAccountName` - Name of the storage account
- `primaryEndpoints` - Object containing service endpoints

---

### 6. storageTable.bicep
**Purpose**: Create table storage within an existing Storage Account.

**Resources Created**:
- Storage Table

**Key Features**:
- References existing Storage Account
- Configurable access policies
- Support for signed identifiers
- Name validation

**Parameters**:
- `storageAccountName` - Name of existing Storage Account
- `storageTableName` - Name of the table to create
- `signedIdentifiers` - Array of access policies

**Outputs**:
- `tableName` - Name of the created table
- `tableResourceId` - Resource ID of the table

**Naming Requirements**:
- Must start with a letter
- 3-63 characters long
- Alphanumeric characters only

---

### 7. virtualNetwork.bicep
**Purpose**: Deploy Virtual Network with preconfigured subnets for the application architecture.

**Resources Created**:
- Virtual Network
- Subnets (App Service, Private Endpoints)

**Key Features**:
- Subnet delegation for App Service
- Private endpoint network policies
- Flexible address space
- Resource tagging support

**Parameters**:
- `virtualNetworkName` - Name of the Virtual Network
- `location` - Deployment location
- `addressPrefix` - VNet address space
- `tags` - Resource tags

**Subnet Configuration**:
- **App Service Subnet**: `10.0.1.0/24` (delegated to Microsoft.Web/serverFarms)
- **Private Endpoints Subnet**: `10.0.2.0/24` (private endpoint policies disabled)

**Outputs**:
- `subnet_ids` - Object containing subnet resource IDs
- `vnet_id` - Resource ID of the Virtual Network
- `virtualNetworkName` - Name of the Virtual Network

## 🔧 Usage Examples

### Using Individual Modules

```bicep
// Deploy just a Key Vault
module keyVaultModule 'modules/keyVault.bicep' = {
  params: {
    keyVaultName: 'kv-myapp-dev'
    location: 'westeurope'
    skuName: 'standard'
    softDeleteEnabled: true
    purgeProtectionEnabled: false
    enabledForTemplateDeployment: true
    diagnosticsEnabled: true
    logAnalyticsWorkspaceId: '/subscriptions/.../workspaces/law-myapp-dev'
  }
}
```

### Module Dependencies

```bicep
// Storage Account depends on Virtual Network
module storageModule 'modules/storageAccount.bicep' = {
  params: {
    storageAccountName: 'stmyappdev'
    location: 'westeurope'
    publicNetworkAccess: 'Disabled'
    diagnosticsEnabled: true
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.log_workspace_id
  }
  dependsOn: [
    virtualNetworkModule
    logAnalyticsModule
  ]
}
```

## 📋 Module Development Guidelines

### Consistency Standards

1. **Parameter Naming**: Use camelCase for all parameters
2. **Resource Naming**: Follow Azure naming conventions
3. **Comments**: Use structured commenting with separators
4. **Outputs**: Always provide resource ID and name at minimum
5. **Location**: Accept location parameter, default to resourceGroup().location
6. **Tags**: Support resource tagging where applicable

### Security Best Practices

1. **Least Privilege**: Configure minimal required permissions
2. **Private Networking**: Support private endpoints where available
3. **Encryption**: Enable encryption by default
4. **Auditing**: Enable diagnostic settings for supported resources
5. **Access Control**: Use RBAC over access policies

### Template Structure

```bicep
//============================================================================
// PARAMETERS
//============================================================================

@description('Parameter description')
param parameterName string

//============================================================================
// RESOURCES
//============================================================================

resource resourceName 'Microsoft.Service/resourceType@api-version' = {
  name: resourceName
  location: location
  properties: {
    // Resource configuration
  }
}

//============================================================================
// OUTPUTS
//============================================================================

output resourceId string = resourceName.id
output resourceName string = resourceName.name
```

## 🔍 Testing Modules

### Validation Testing

```powershell
# Test individual module syntax
az bicep build --file modules/keyVault.bicep

# Validate with parameters
az deployment group validate --resource-group "test-rg" --template-file "modules/keyVault.bicep" --parameters keyVaultName="kv-test" location="westeurope"
```

### Integration Testing

```powershell
# Deploy module individually for testing
az deployment group create --resource-group "test-rg" --template-file "modules/keyVault.bicep" --parameters keyVaultName="kv-test-$(Get-Random)" location="westeurope"
```

## 📚 Additional Resources

- [Azure Bicep Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Azure Resource Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Azure Resource Manager Template Reference](https://docs.microsoft.com/azure/templates/)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)