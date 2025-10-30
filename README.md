# Azure Bicep Infrastructure Demo Project

🚀 **Demo Project** - A comprehensive Azure infrastructure deployment using Bicep templates with GitHub Actions CI/CD, showcasing modern cloud architecture patterns, security best practices, and automated deployment workflows.

> **Note**: This is a demonstration project designed to showcase Azure Bicep capabilities and is not intended for production maintenance.

## 🏗️ Architecture Overview

This demo project deploys a complete Azure infrastructure stack with the following components:

- **App Service** - Node.js web application with VNet integration
- **Key Vault** - Secure secret management with private endpoint
- **Storage Account** - Table storage with private endpoint
- **Log Analytics Workspace** - Centralized logging and monitoring
- **Virtual Network** - Private networking with dedicated subnets
- **Private Endpoints** - Secure private connectivity for PaaS services
- **GitHub Actions** - Automated CI/CD pipeline for infrastructure deployment

## 📁 Project Structure

```
bicep-lab/
├── main.bicep                    # Main orchestration template
├── main.bicepparam              # Parameter values file
├── README.md                    # This documentation
├── docs/
│   ├── DEPLOYMENT.md           # Deployment guide
│   ├── ARCHITECTURE.md         # Detailed architecture documentation
│   └── TROUBLESHOOTING.md      # Common issues and solutions
|   └── Architecture Diagram.drawio # draw.io diagram for project architecture 
├── modules/                    # Reusable Bicep modules
│   ├── appService.bicep        # App Service and hosting plan
│   ├── keyVault.bicep          # Key Vault with RBAC
│   ├── logAnalyticsWorkspace.bicep # Log Analytics workspace
│   ├── privateEndpoint.bicep   # Private endpoint template
│   ├── storageAccount.bicep    # Storage account with security
│   ├── storageTable.bicep      # Table storage
│   └── virtualNetwork.bicep    # VNet with subnets
└── roles/                      # RBAC role assignments
    ├── roles.bicep             # Role assignment templates
    └── roles.bicepparam        # Role assignment parameters
```

## 🚀 Quick Start (GitHub Actions Deployment)

### Prerequisites

- **GitHub Repository** with this code
- **Azure Subscription** with appropriate permissions
- **GitHub Secrets** configured (see setup below)

### Automated Deployment Setup

This project uses **GitHub Actions** for automated deployment. No local Azure CLI installation required!

1. **Fork/Clone the repository**
   ```bash
   git clone <repository-url>
   cd bicep-lab
   ```

2. **Configure GitHub Secrets**
   
   In your GitHub repository, go to `Settings > Secrets and variables > Actions` and add:
   
   ```
   AZURE_CREDENTIALS     = {"clientId":"xxx","clientSecret":"xxx","subscriptionId":"xxx","tenantId":"xxx"}
   JWT_SECRET           = your-jwt-secret-value
   ddimitr_dummy_password = your-ddimitr-password
   hello_dummy_password   = your-hello-password
   ```

3. **Automatic Deployment**
   
   The workflow triggers automatically on:
   - Push to `main` branch (when infrastructure files change)
   - Manual trigger via GitHub Actions UI
   
   ```bash
   git add .
   git commit -m "Deploy infrastructure"
   git push origin main
   ```

### Manual Local Deployment (Alternative)

For local testing, you can still deploy manually:
```powershell
az login
az group create --name "rg-taskGen-dev-weu" --location "westeurope"
az deployment group create --resource-group "rg-taskGen-dev-weu" --parameters main.bicepparam --template-file main.bicep
```

## 🔧 Configuration

### Environment Variables

The deployment supports multiple environments through the `environment` parameter:
- `dev` - Development environment
- `test` - Testing environment  
- `prod` - Production environment

### Naming Convention

Resources follow Azure naming best practices:
- **Resource Groups**: `rg-{workload}-{environment}`
- **App Service**: `app-{workload}-{environment}`
- **Key Vault**: `kv-{workload}-{environment}`
- **Storage Account**: `st{workload}{environment}{uniqueString}`
- **Log Analytics**: `law-{workload}-{environment}`
- **Virtual Network**: `vnet-{workload}-{environment}`
- **Private Endpoints**: `pe-{workload}-{environment}-{service}`

## 🔐 Security Features

### Network Security
- **Private Endpoints** for Key Vault and Storage Account
- **VNet Integration** for App Service
- **Private DNS Zones** for name resolution
- **Network Security Groups** (configurable)

### Access Control
- **Managed Identity** for App Service
- **RBAC** role assignments
- **Key Vault access policies**
- **Storage Account access restrictions**

### Data Protection
- **Soft delete** enabled for Key Vault
- **Encryption at rest** for all storage
- **TLS encryption** in transit
- **Diagnostic logging** enabled

## 📊 Monitoring & Logging

### Centralized Logging
All supported resources send logs and metrics to Log Analytics:
- ✅ **App Service**: Application logs, HTTP logs, performance metrics
- ✅ **Key Vault**: Audit events, access logs
- ✅ **Storage Account**: Transaction logs, capacity metrics
- ✅ **Log Analytics**: Workspace usage and audit logs

### Monitoring Capabilities
- **Application Performance Monitoring** via App Service logs
- **Security Monitoring** via Key Vault audit logs
- **Storage Operations** via Storage Account diagnostics
- **Network Flow Logs** (optional, can be enabled)

## 🔍 Outputs

The main template provides these outputs:
- `subnetIds` - Object containing all subnet resource IDs
- `storageAccountId` - Storage Account resource ID
- `keyVaultId` - Key Vault resource ID
- `appServicePrincipalId` - App Service managed identity ID
- `logAnalyticsWorkspaceId` - Log Analytics workspace resource ID

## 📚 Documentation

- [**GitHub Actions CI/CD**](docs/GITHUB_ACTIONS.md) - Automated deployment pipeline setup and configuration
- [**Architecture Documentation**](docs/ARCHITECTURE.md) - Detailed architecture and design decisions
- [**Deployment Guide**](docs/DEPLOYMENT.md) - Manual deployment instructions (alternative to GitHub Actions)
- [**Troubleshooting**](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🎯 Demo Project Notes

This is a **demonstration project** showcasing:
- ✅ **Modern Azure Architecture** patterns
- ✅ **Infrastructure as Code** with Bicep
- ✅ **Security Best Practices** (private endpoints, RBAC, Key Vault)
- ✅ **Automated CI/CD** with GitHub Actions
- ✅ **Comprehensive Monitoring** with Log Analytics
- ✅ **Professional Documentation** standards

### Key Learning Points
- **Bicep Modules**: Reusable, maintainable infrastructure components
- **Private Networking**: Secure Azure PaaS services with private endpoints
- **GitHub Actions**: Infrastructure deployment automation
- **Azure Security**: RBAC, managed identities, and secret management
- **Monitoring**: Centralized logging and diagnostics

## 📄 License

This demo project is provided as-is for educational purposes. Feel free to use and modify for learning and demonstration.

## 🏷️ Tags

`azure` `bicep` `infrastructure-as-code` `app-service` `key-vault` `storage-account` `private-networking` `logging` `monitoring`