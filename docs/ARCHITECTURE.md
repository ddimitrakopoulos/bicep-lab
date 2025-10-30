# Architecture Documentation

This document provides detailed information about the Azure infrastructure architecture, design decisions, and technical specifications.

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                       │
├─────────────────────────────────────────────────────────────────┤
│                      Resource Group                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  Log Analytics Workspace                    ││
│  │              (Centralized Logging)                         ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   Virtual Network                           ││
│  │  ┌─────────────────┐  ┌─────────────────────────────────────┐││
│  │  │   App Service   │  │      Private Endpoints              │││
│  │  │     Subnet      │  │         Subnet                      │││
│  │  │   (Delegated)   │  │  ┌─────────────┐ ┌─────────────────┐│││
│  │  │                 │  │  │ Key Vault   │ │ Storage Account ││││
│  │  │  ┌─────────────┐│  │  │Private      │ │ Private         ││││
│  │  │  │ App Service ││  │  │Endpoint     │ │ Endpoint        ││││
│  │  │  │             ││  │  └─────────────┘ └─────────────────┘│││
│  │  │  └─────────────┘│  │                                     │││
│  │  └─────────────────┘  └─────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Key Vault     │  │ Storage Account │  │ Private DNS     │ │
│  │                 │  │                 │  │     Zones       │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │                 │ │
│  │ │  Secrets    │ │  │ │Table Storage│ │  │ *.vault.azure.  │ │
│  │ │- JWT Secret │ │  │ │             │ │  │ *.table.core.   │ │
│  │ │- User Pwds  │ │  │ └─────────────┘ │  │                 │ │
│  │ └─────────────┘ │  └─────────────────┘  └─────────────────┘ │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Component Details

### 1. App Service

**Purpose**: Host the Node.js web application with secure networking and monitoring.

**Specifications**:
- **Runtime**: Node.js 20.x
- **Plan Type**: App Service Plan (B1 for dev, P1V2+ for prod)
- **Networking**: VNet integrated with dedicated subnet
- **Identity**: System-assigned managed identity
- **Monitoring**: Diagnostic settings enabled

**Security Features**:
- VNet integration for outbound traffic
- Managed identity for Azure resource access
- HTTPS only enforcement
- Application logging enabled

**Configuration**:
```bicep
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      vnetRouteAllEnabled: true
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
    }
    virtualNetworkSubnetId: subnetId
  }
  identity: {
    type: 'SystemAssigned'
  }
}
```

### 2. Key Vault

**Purpose**: Secure storage for application secrets and configuration.

**Specifications**:
- **SKU**: Standard
- **Access Model**: RBAC-based access control
- **Soft Delete**: Enabled (configurable retention)
- **Purge Protection**: Environment-dependent
- **Networking**: Private endpoint only

**Stored Secrets**:
- `jwtsecret` - JWT signing key for authentication
- `ddimitrpass` - User password for ddimitr user
- `hellopass` - User password for hello user

**Security Features**:
- Private endpoint for network isolation
- RBAC for granular access control
- Audit logging to Log Analytics
- Soft delete protection
- ARM template deployment access

### 3. Storage Account

**Purpose**: Provide table storage for application data with secure access.

**Specifications**:
- **Type**: StorageV2 (General Purpose v2)
- **Replication**: LRS (Locally Redundant Storage)
- **Access Tier**: Hot
- **Networking**: Private endpoint only
- **Public Access**: Disabled

**Services**:
- **Table Storage**: Primary data storage for the application
- **Blob Storage**: Available but not actively used
- **File Storage**: Available for future use

**Security Features**:
- Private endpoint with private DNS
- Public network access disabled
- Encryption at rest with platform-managed keys
- Diagnostic logging enabled

### 4. Virtual Network

**Purpose**: Provide network isolation and secure communication between resources.

**Network Design**:
- **Address Space**: `10.0.0.0/16`
- **App Service Subnet**: `10.0.1.0/24` (delegated to Microsoft.Web/serverFarms)
- **Private Endpoints Subnet**: `10.0.2.0/24` (private endpoint policies disabled)

**Subnets**:
```bicep
subnets: [
  {
    name: 'appservice'
    properties: {
      addressPrefix: '10.0.1.0/24'
      delegations: [{
        name: 'webapp-delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }]
    }
  }
  {
    name: 'private-endpoints'
    properties: {
      addressPrefix: '10.0.2.0/24'
      privateEndpointNetworkPolicies: 'Disabled'
    }
  }
]
```

### 5. Private Endpoints

**Purpose**: Provide secure, private connectivity to PaaS services.

**Endpoints Configured**:
- **Key Vault Private Endpoint**
  - Service: `Microsoft.KeyVault/vaults`
  - Group ID: `vault`
  - DNS Zone: `privatelink.vaultcore.azure.net`
  
- **Storage Account Private Endpoint**
  - Service: `Microsoft.Storage/storageAccounts`
  - Group ID: `table`
  - DNS Zone: `privatelink.table.core.windows.net`

**DNS Configuration**:
- Private DNS zones linked to VNet
- Automatic DNS record creation for private endpoints
- Split-horizon DNS resolution

### 6. Log Analytics Workspace

**Purpose**: Centralized logging and monitoring for all infrastructure components.

**Configuration**:
- **SKU**: PerGB2018 (Pay-as-you-go)
- **Retention**: 30 days (dev), 90 days (prod)
- **Location**: Same as other resources

**Data Sources**:
- App Service application logs and metrics
- Key Vault audit events
- Storage Account transaction logs
- Workspace audit events

## 🔐 Security Architecture

### Network Security

**Zero Trust Principles**:
- All PaaS services accessed via private endpoints
- No public internet access to storage or key vault
- App Service integrated with VNet for outbound traffic
- Private DNS zones for name resolution

**Traffic Flow**:
1. **Inbound**: Internet → App Service (HTTPS only)
2. **App Service → Key Vault**: Via private endpoint
3. **App Service → Storage**: Via private endpoint  
4. **Management**: Azure portal access via private endpoints

### Identity and Access Management

**Managed Identities**:
- App Service uses system-assigned managed identity
- No service principal credentials stored in code
- RBAC assignments for resource access

**Key Vault Access**:
- RBAC-based permissions (no access policies)
- Principle of least privilege
- Audit trail for all secret access

### Data Protection

**Encryption**:
- **In Transit**: TLS 1.2+ for all connections
- **At Rest**: Platform-managed encryption for all services
- **Key Management**: Azure-managed keys (option for customer-managed)

**Backup and Recovery**:
- Key Vault soft delete enabled
- Storage Account versioning available
- App Service deployment slots for blue-green deployments

## 📊 Monitoring and Observability

### Diagnostic Settings

All supported resources configured with diagnostic settings:

```bicep
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-settings'
  scope: resourceName
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}
```

### Logging Capabilities

| Resource | Logs Available | Metrics Available |
|----------|----------------|-------------------|
| App Service | ✅ HTTP logs, App logs, Platform logs | ✅ All metrics |
| Key Vault | ✅ Audit events, Policy evaluation | ✅ All metrics |
| Storage Account | ✅ Transaction logs | ✅ Transaction & Capacity metrics |
| Log Analytics | ✅ Audit events | ✅ Usage metrics |
| Virtual Network | ❌ No diagnostic settings | ❌ No diagnostic settings |
| Private Endpoints | ❌ No diagnostic settings | ❌ No diagnostic settings |

### Alerting Strategy

**Recommended Alerts**:
- App Service HTTP 5xx errors > threshold
- Key Vault access failures
- Storage Account throttling events
- Log Analytics data ingestion limits

## 🚀 Scalability Considerations

### App Service Scaling

**Vertical Scaling**:
- B1 → S1 → P1V2 → P2V2 → P3V2
- Consider Premium v3 for production workloads

**Horizontal Scaling**:
- Auto-scaling rules based on CPU/Memory
- Scale out to multiple instances
- Consider App Service Environment for isolation

### Storage Scaling

**Table Storage**:
- Virtually unlimited capacity
- Automatic partitioning
- Consider partition key design for optimal performance

**Throughput**:
- Standard: Up to 20,000 requests/second
- Premium: Higher throughput available

### Network Scaling

**Bandwidth**:
- App Service: Depends on pricing tier
- Private Endpoints: No bandwidth limits
- VNet: Regional bandwidth limits apply

## 🔄 Disaster Recovery

### Recovery Strategies

**App Service**:
- Deployment slots for quick rollback
- Backup/restore functionality
- Multi-region deployment possible

**Key Vault**:
- Soft delete protection
- Backup to secondary region
- Cross-region replication available

**Storage Account**:
- LRS within region
- GRS/RA-GRS for cross-region replication
- Point-in-time restore for blobs

### Business Continuity

**RTO/RPO Targets**:
- **RTO** (Recovery Time Objective): < 1 hour
- **RPO** (Recovery Point Objective): < 15 minutes

**Backup Strategy**:
- Automated backups for App Service
- Key Vault secret versioning
- Storage Account soft delete

## 📈 Performance Optimization

### App Service Optimization

**Configuration**:
- Always On enabled for production
- ARR Affinity disabled for stateless apps
- Connection pooling optimization
- Application Insights integration

### Storage Optimization

**Table Storage**:
- Optimal partition key selection
- Batch operations for multiple entities
- Proper indexing strategy
- Connection string optimization

### Network Optimization

**Private Endpoints**:
- Single private endpoint per service
- Optimal subnet sizing
- DNS caching optimization
- Regional proximity

## 🔧 Maintenance and Updates

### Regular Maintenance Tasks

**Monthly**:
- Review Log Analytics retention policies
- Check Key Vault certificate expiration
- Update App Service runtime versions
- Review security recommendations

**Quarterly**:
- Review and optimize costs
- Update Bicep templates
- Security assessment and penetration testing
- Disaster recovery testing

**Annually**:
- Architecture review
- Technology stack updates
- Compliance audit
- Capacity planning review