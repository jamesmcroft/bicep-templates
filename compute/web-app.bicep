@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the App Service Plan associated with the Web App.')
param appServicePlanId string
@description('Web App Kind. Defaults to app,linux.')
param kind string = 'app,linux'
@description('App settings for the Web App.')
param appSettings array = []
@description('ID for the Managed Identity associated with the Web App.')
param identityId string
@description('Public network access for the Web App. Defaults to Enabled.')
param publicNetworkAccess string = 'Enabled'

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
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
    }
    keyVaultReferenceIdentity: identityId
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccess
  }
}

@description('The deployed Web App resource.')
output resource resource = webApp
@description('ID for the deployed Web App resource.')
output id string = webApp.id
@description('Name for the deployed Web App resource.')
output name string = webApp.name
@description('Host for the deployed Web App resource.')
output host string = webApp.properties.defaultHostName
