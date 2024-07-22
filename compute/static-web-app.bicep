@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for Static Web App.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'Free' | 'Standard'
}

@description('Static Web App SKU. Defaults to Free.')
param sku skuInfo = {
  name: 'Free'
}

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    allowConfigFileUpdates: true
    stagingEnvironmentPolicy: 'Disabled'
  }
}

@description('The deployed Static Web App resource.')
output resource resource = staticWebApp
@description('ID for the deployed Static Web App resource.')
output id string = staticWebApp.id
@description('Name for the deployed Static Web App resource.')
output name string = staticWebApp.name
@description('URL for the deployed Static Web App resource.')
output url string = staticWebApp.properties.defaultHostname
