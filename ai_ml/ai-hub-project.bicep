@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the Storage Account associated with the AI Hub project.')
param storageAccountId string
@description('ID for the Key Vault associated with the AI Hub project.')
param keyVaultId string
@description('ID for the Application Insights associated with the AI Hub project.')
param applicationInsightsId string
@description('Name for the AI Hub resource associated with the AI Hub project.')
param aiHubName string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' existing = {
  name: aiHubName
}

resource aiHubProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'Project'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: name
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    hubResourceId: aiHub.id
  }
}

@description('The deployed AI Hub project resource.')
output resource resource = aiHubProject
@description('ID for the deployed AI Hub project resource.')
output id string = aiHubProject.id
@description('Name for the deployed AI Hub project resource.')
output name string = aiHubProject.name
