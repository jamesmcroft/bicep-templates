@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}
@description('ID for the Managed Identity associated with the API Management resource.')
param apiManagementIdentityId string

@export()
@description('Information about the configuration for a virtual network for the API Management service.')
type vnetConfigInfo = {
  @description('Resource ID of a subnet for the API Management service.')
  subnetResourceId: string
  @description('Type of virtual network.')
  virtualNetworkType: 'Internal' | 'External' | 'None'
}

@export()
@description('SKU information for API Management.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'Developer' | 'Standard' | 'Premium' | 'Basic' | 'Consumption' | 'Isolated' | 'BasicV2' | 'StandardV2'
  @description('Capacity of the SKU.')
  capacity: 1 | 2
}

@description('Email address of the owner for the API Management resource.')
@minLength(1)
param publisherEmail string
@description('Name of the owner for the API Management resource.')
@minLength(1)
param publisherName string
@description('API Management SKU. Defaults to Developer, capacity 1.')
param sku skuInfo = {
  name: 'Developer'
  capacity: 1
}
@description('Virtual network configuration for the API Management resource.')
param vnetConfig vnetConfigInfo = {
  subnetResourceId: ''
  virtualNetworkType: 'None'
}
@description('Certificates for the API Management resource.')
param certificates object[] = []
@description('Hostname configurations for the API Management resource.')
param hostnameConfigurations object[] = []

resource apiManagement 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: sku
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${apiManagementIdentityId}': {}
    }
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkConfiguration: !empty(vnetConfig.subnetResourceId)
      ? { subnetResourceId: vnetConfig.subnetResourceId }
      : null
    certificates: certificates
    hostnameConfigurations: hostnameConfigurations
    virtualNetworkType: !empty(vnetConfig.virtualNetworkType) ? vnetConfig.virtualNetworkType : 'None'
  }
}

@description('The deployed API Management resource.')
output resource resource = apiManagement
@description('ID for the deployed API Management resource.')
output id string = apiManagement.id
@description('Name for the deployed API Management resource.')
output name string = apiManagement.name
@description('Gateway URL for the deployed API Management resource.')
output gatewayUrl string = apiManagement.properties.gatewayUrl
@description('Host for the deployed API Management resource.')
output host string = split(apiManagement.properties.gatewayUrl, '/')[2]
@description('Private IP address for the deployed API Management resource.')
output privateIp string = apiManagement.properties.privateIPAddresses[0]
