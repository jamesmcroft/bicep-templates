@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
    name: 'Free' | 'Standard'
}

@description('Static Web App SKU. Defaults to Free.')
param sku skuInfo = {
    name: 'Free'
}

resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
    name: name
    location: location
    sku: sku
    properties: {
        allowConfigFileUpdates: true
        stagingEnvironmentPolicy: 'Disabled'
    }
}

@description('ID for the deployed Static Web App resource.')
output id string = staticWebApp.id
@description('Name for the deployed Static Web App resource.')
output name string = staticWebApp.name
@description('URL for the deployed Static Web App resource.')
output url string = staticWebApp.properties.defaultHostname
