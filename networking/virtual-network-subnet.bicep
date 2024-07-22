@description('Name of the resource.')
param name string

@description('Name of the existing virtual network to deploy the subnet to.')
param virtualNetworkName string
@description('The address block reserved for this virtual network subnet in CIDR notation.')
param addressPrefix string
@description('List of service delegations in this virtual network subnet.')
param delegations object[]?

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  name: name
  parent: virtualNetwork
  properties: {
    addressPrefix: addressPrefix
    delegations: delegations
  }
}

@description('ID for the deployed Virtual Network subnet resource.')
output id string = subnet.id
@description('Name for the deployed Virtual Network subnet resource.')
output name string = subnet.name
