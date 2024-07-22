@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('SKU for the Public IP Address. Defaults to Standard.')
param skuName 'Basic' | 'Standard' = 'Standard'
@description('Allocation method for the Public IP Address. Defaults to Static.')
param allocationMethod 'Static' | 'Dynamic' = 'Static'

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    publicIPAllocationMethod: allocationMethod
  }
}

@description('The deployed Public IP Address resource.')
output resource resource = publicIpAddress
@description('ID for the deployed Public IP Address resource.')
output id string = publicIpAddress.id
@description('Name for the deployed Public IP Address resource.')
output name string = publicIpAddress.name
@description('IP Address for the deployed Public IP Address resource.')
output ipAddress string = publicIpAddress.properties.ipAddress
