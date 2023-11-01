@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the App Service Plan associated with the Function App.')
param appServicePlanId string
@description('App settings for the Function App.')
param appSettings array = []
@description('Whether the Function App is Linux-based. Defaults to true.')
param isLinux bool = true
@description('ID for the Managed Identity associated with the Function App.')
param functionAppIdentityId string

var kind = isLinux ? 'functionapp,linux' : 'functionapp'

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
    name: name
    location: location
    tags: tags
    kind: kind
    identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${functionAppIdentityId}': {}
        }
    }
    properties: {
        serverFarmId: appServicePlanId
        siteConfig: {
            appSettings: appSettings
        }
        keyVaultReferenceIdentity: functionAppIdentityId
    }
}

@description('The deployed Function App resource.')
output resource resource = functionApp
@description('ID for the deployed Function App resource.')
output id string = functionApp.id
@description('Name for the deployed Function App resource.')
output name string = functionApp.name
@description('URL for the deployed Function App resource.')
output url string = functionApp.properties.defaultHostName
