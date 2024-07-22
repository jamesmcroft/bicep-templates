@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('List of address blocks reserved for this virtual network in CIDR notation.')
param addressPrefixes string[] = ['10.0.0.0/16']

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}

@description('ID for the deployed Virtual Network resource.')
output id string = virtualNetwork.id
@description('Name for the deployed Virtual Network resource.')
output name string = virtualNetwork.name
