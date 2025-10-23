param(
    [string]$KeyVaultName,
    [string]$AppServiceName,
    [string]$ResourceGroup
)

# Get the App Service's principal (Managed Identity) ID
$PrincipalId = az webapp identity show `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --query principalId `
    -o tsv

Write-Host "Principal ID of $AppServiceName is $PrincipalId"

# Get the Key Vault resource ID
$KeyVaultId = az keyvault show `
    --name $KeyVaultName `
    --query id `
    -o tsv

Write-Host "Key Vault resource ID is $KeyVaultId"

# Assign 'Key Vault Secrets User' role to the App Service
az role assignment create `
    --assignee $PrincipalId `
    --role "Key Vault Secrets User" `
    --scope $KeyVaultId

Write-Host "RBAC role 'Key Vault Secrets User' assigned to $AppServiceName successfully."
