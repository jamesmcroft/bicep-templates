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
@description('ID for the Managed Identity associated with the Function App.')
param identityId string
@description('Version of the runtime to use for the Function App. Defaults to .NET 8.0 Isolated.')
param linuxFxVersion string = 'DOTNET-ISOLATED|8.0'
@description('Public network access for the Function App. Defaults to Enabled.')
param publicNetworkAccess string = 'Enabled'

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      appSettings: appSettings
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
    }
    keyVaultReferenceIdentity: identityId
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
  }
}

@description('The deployed Function App resource.')
output resource resource = functionApp
@description('ID for the deployed Function App resource.')
output id string = functionApp.id
@description('Name for the deployed Function App resource.')
output name string = functionApp.name
@description('Host for the deployed Function App resource.')
output host string = functionApp.properties.defaultHostName
