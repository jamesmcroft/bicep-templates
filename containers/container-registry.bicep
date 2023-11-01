@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
    name: 'Basic' | 'Premium' | 'Standard'
}

@description('Whether to enable an admin user that has push and pull access. Defaults to false.')
param adminUserEnabled bool = false
@description('Whether to allow public network access. Defaults to Disabled.')
@allowed([
    'Disabled'
    'Enabled'
])
param publicNetworkAccess string = 'Disabled'
@description('Container Registry SKU. Defaults to Basic.')
param sku skuInfo = {
    name: 'Basic'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
    name: name
    location: location
    tags: tags
    identity: {
        type: 'SystemAssigned'
    }
    sku: sku
    properties: {
        adminUserEnabled: adminUserEnabled
        publicNetworkAccess: publicNetworkAccess
    }
}

@description('ID for the deployed Container Registry resource.')
output id string = containerRegistry.id
@description('Name for the deployed Container Registry resource.')
output name string = containerRegistry.name
@description('Login server for the deployed Container Registry resource.')
output loginServer string = containerRegistry.properties.loginServer
