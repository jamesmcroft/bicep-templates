@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the Storage Account associated with the ML workspace.')
param storageAccountId string
@description('ID for the Key Vault associated with the ML workspace.')
param keyVaultId string
@description('ID for the Application Insights associated with the ML workspace.')
param applicationInsightsId string
@description('ID for the Container Registry associated with the ML workspace.')
param containerRegistryId string
@description('Whether to reduce telemetry collection and enable additional encryption. Defaults to false.')
param enableHealthBehaviorInsight bool = false
@description('ID for the Managed Identity associated with the ML workspace.')
param identityId string

resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2022-10-01' = {
    name: name
    location: location
    tags: tags
    identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${identityId}': {}
        }
    }
    properties: {
        friendlyName: name
        storageAccount: storageAccountId
        keyVault: keyVaultId
        applicationInsights: applicationInsightsId
        containerRegistry: containerRegistryId
        hbiWorkspace: enableHealthBehaviorInsight
        primaryUserAssignedIdentity: identityId
    }
}

@description('The deployed ML workspace resource.')
output resource resource = mlWorkspace
@description('ID for the deployed ML workspace resource.')
output id string = mlWorkspace.id
@description('Name for the deployed ML workspace resource.')
output name string = mlWorkspace.name
