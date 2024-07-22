@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('Information about the configuration for autoscaling the Application Gateway resource.')
type autoscaleConfigInfo = {
  @description('Minimum number of instances.')
  minCapacity: int
  @description('Maximum number of instances.')
  maxCapacity: int
}

@description('SKU for the Application Gateway. Defaults to Standard_v2.')
param skuName 'Standard_v2' | 'WAF_v2' = 'Standard_v2'
@description('ID for the Managed Identity associated with the Application Gateway resource.')
param appGatewayIdentityId string
@description('ID for the Subnet resource associated with the Application Gateway resource.')
param subnetId string
@description('ID for the Public IP Address resource associated with the Application Gateway resource.')
param publicIpAddressId string
@description('Autoscale configuration for the Application Gateway resource. Defaults to a minimum capacity of 1 and a maximum capacity of 2.')
param autoscaleConfig autoscaleConfigInfo = {
  minCapacity: 1
  maxCapacity: 2
}

var appGatewayId = resourceId('Microsoft.Network/applicationGateways', name)

resource appGateway 'Microsoft.Network/applicationGateways@2024-01-01' = {
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
    sku: {
      name: skuName
      tier: skuName
    }
    autoscaleConfiguration: autoscaleConfig
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
    backendAddressPools: [
      {
        name: 'agw-default-backend-pool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'www.contoso.com'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'agw-default-backend-http-settings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          pickHostNameFromBackendAddress: true
          probeEnabled: false
        }
      }
    ]
    httpListeners: [
      {
        name: 'agw-http-listener'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: '${appGatewayId}/frontendIPConfigurations/agw-frontend-ipconfig'
          }
          frontendPort: {
            id: '${appGatewayId}/frontendPorts/agw-frontend-port'
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'agw-http-routing-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 1
          httpListener: {
            id: '${appGatewayId}/httpListeners/agw-http-listener'
          }
          urlPathMap: {
            id: '${appGatewayId}/urlPathMaps/agw-url-path-map'
          }
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'agw-url-path-map'
        properties: {
          defaultBackendAddressPool: {
            id: '${appGatewayId}/backendAddressPools/agw-default-backend-pool'
          }
          defaultBackendHttpSettings: {
            id: '${appGatewayId}/backendHttpSettingsCollection/agw-default-backend-http-settings'
          }
          pathRules: [
            {
              name: 'agw-cleanup-path-rule'
              properties: {
                paths: [
                  '/delete'
                ]
                backendAddressPool: {
                  id: '${appGatewayId}/backendAddressPools/agw-default-backend-pool'
                }
                backendHttpSettings: {
                  id: '${appGatewayId}/backendHttpSettingsCollection/agw-default-backend-http-settings'
                }
              }
            }
          ]
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
