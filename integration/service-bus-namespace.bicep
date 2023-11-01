@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
    name: 'Basic' | 'Premium' | 'Standard'
}

type serviceBusConfigInfo = {
    disableLocalAuth: bool
    zoneRedundant: bool
}

@description('Service Bus Namespace SKU. Defaults to Basic.')
param sku skuInfo = {
    name: 'Basic'
}
@description('Service Bus Namespace configuration.')
param serviceBusConfig serviceBusConfigInfo = {
    disableLocalAuth: false
    zoneRedundant: false
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
    name: name
    location: location
    tags: tags
    sku: sku
    properties: {
        disableLocalAuth: serviceBusConfig.disableLocalAuth
        zoneRedundant: serviceBusConfig.zoneRedundant
    }
}

@description('The deployed Service Bus Namespace resource.')
output resource resource = serviceBusNamespace
@description('ID for the deployed Service Bus Namespace resource.')
output id string = serviceBusNamespace.id
@description('Name for the deployed Service Bus Namespace resource.')
output name string = serviceBusNamespace.name
