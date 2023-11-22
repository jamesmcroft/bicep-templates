@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the Storage Account associated with the AI Workspace.')
param storageAccountId string
@description('ID for the Key Vault associated with the AI Workspace.')
param keyVaultId string
@description('ID for the Application Insights associated with the AI Workspace.')
param applicationInsightsId string
@description('ID for the Container Registry associated with the AI Workspace.')
param containerRegistryId string
@description('ID for the Managed Identity associated with the AI Workspace.')
param identityId string

resource aiWorkspace 'Microsoft.MachineLearningServices/workspaces@2022-12-01-preview' = {
    name: name
    location: location
    tags: tags
    kind: 'Hub'
    identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${identityId}': {}
        }
    }
    sku:{
        name: 'Basic'
        tier: 'Basic'
    }
    properties: {
        friendlyName: name
        storageAccount: storageAccountId
        keyVault: keyVaultId
        applicationInsights: applicationInsightsId
        containerRegistry: containerRegistryId
        primaryUserAssignedIdentity: identityId
    }
}

@description('The deployed AI Workspace resource.')
output resource resource = aiWorkspace
@description('ID for the deployed AI Workspace resource.')
output id string = aiWorkspace.id
@description('Name for the deployed AI Workspace resource.')
output name string = aiWorkspace.name
