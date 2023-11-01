@description('Name of the secret.')
param name string

@description('Name of the Key Vault associated with the secret.')
param keyVaultName string
@description('Value of the secret.')
@secure()
param value string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
    name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
    name: name
    parent: keyVault
    properties: {
        value: value
        attributes: {
            enabled: true
        }
    }
}

@description('ID for the deployed Key Vault Secret resource.')
output id string = keyVaultSecret.id
@description('Name for the deployed Key Vault Secret resource.')
output name string = keyVaultSecret.name
@description('URI for the deployed Key Vault Secret resource.')
output uri string = keyVaultSecret.properties.secretUri
