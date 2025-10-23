param(
    [string]$KeyVaultName,
    [string]$AppServiceName,
    [string]$ResourceGroup
)

# Get the principal ID of the App Service
$PrincipalId = az webapp identity show `
    --name $AppServiceName `
    --resource-group $ResourceGroup `
    --query principalId `
    -o tsv

Write-Host "Principal ID of $AppServiceName is $PrincipalId"

# Assign Key Vault permissions
az keyvault set-policy `
    --name $KeyVaultName `
    --object-id $PrincipalId `
    --secret-permissions get list `
    --key-permissions get list

Write-Host "Key Vault policy assigned successfully"
