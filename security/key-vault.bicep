@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('Key Vault SKU name. Defaults to standard.')
@allowed([
    'standard'
    'premium'
])
param skuName string = 'standard'
@description('Whether soft deletion is enabled. Defaults to true.')
param enableSoftDelete bool = true

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
    name: name
    location: location
    tags: tags
    properties: {
        sku: {
            family: 'A'
            name: skuName
        }
        tenantId: subscription().tenantId
        networkAcls: {
            defaultAction: 'Allow'
            bypass: 'AzureServices'
        }
        enableSoftDelete: enableSoftDelete
        enabledForTemplateDeployment: true
        enableRbacAuthorization: true
    }
}

@description('ID for the deployed Key Vault resource.')
output id string = keyVault.id
@description('Name for the deployed Key Vault resource.')
output name string = keyVault.name
@description('URI for the deployed Key Vault resource.')
output uri string = keyVault.properties.vaultUri
