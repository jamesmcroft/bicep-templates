@description('Name of the resource.')
param name string

@description('Name for the Container Apps Environment associated with the Dapr component.')
param containerAppsEnvironmentName string
@description('Name of the Key Vault associated with the Dapr component.')
param keyVaultName string
@description('Client ID for the Managed Identity associated with the Dapr component.')
param identityClientId string
@description('Container App names for the scopes to configure for the Dapr component.')
param scopes array = []

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
    name: containerAppsEnvironmentName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
    name: name
    parent: containerAppsEnvironment
    properties: {
        componentType: 'secretstores.azure.keyvault'
        version: 'v1'
        ignoreErrors: false
        initTimeout: '5s'
        metadata: [
            {
                name: 'vaultName'
                value: keyVaultName
            }
            {
                name: 'azureClientId'
                value: identityClientId
            }
        ]
        scopes: scopes
    }
}

@description('The deployed Dapr component resource.')
output resource resource = daprComponent
@description('ID for the deployed Dapr component resource.')
output id string = daprComponent.id
@description('Name for the deployed Dapr component resource.')
output name string = daprComponent.name
