@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the Managed Identity associated with the Application Gateway resource.')
param appGatewayIdentityId string
@description('ID for the Subnet resource associated with the Application Gateway resource.')
param subnetId string
@description('ID for the Public IP Address resource associated with the Application Gateway resource.')
param publicIpAddressId string

resource appGateway 'Microsoft.Network/applicationGateways@2022-07-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentityId}': {}
    }
  }
  properties: {
    gatewayIPConfigurations: [
      {
        name: 'agw-ipconfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'agw-frontend-ipconfig'
        properties: {
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'agw-frontend-port'
        properties: {
          port: 80
        }
      }
    ]
  }
}

@description('The deployed Application Gateway resource.')
output resource resource = appGateway
@description('ID for the deployed Application Gateway resource.')
output id string = appGateway.id
@description('Name for the deployed Application Gateway resource.')
output name string = appGateway.name
