@description('Name of the resource.')
param name string
@description('Tags for the resource.')
param tags object = {}

type backendInfo = {
  address: string
  httpPort: int
  httpsPort: int
  priority: int
  weight: int
  backendHostHeader: string
}

@description('Backend configurations for the Front Door resource.')
param backends backendInfo[]

resource frontDoor 'Microsoft.Network/frontDoors@2021-06-01' = {
  name: name
  location: 'global'
  tags: tags
  properties: {
    friendlyName: name
    enabledState: 'Enabled'
    healthProbeSettings: [
      {
        name: 'healthProbeSettings'
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 30
          healthProbeMethod: 'HEAD'
          enabledState: 'Enabled'
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: 'loadBalancingSettings'
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
          additionalLatencyMilliseconds: 0
        }
      }
    ]
    frontendEndpoints: [
      {
        name: 'frontendEndpoint'
        properties: {
          hostName: '${name}.azurefd.net'
          sessionAffinityEnabledState: 'Enabled'
          sessionAffinityTtlSeconds: 0
          webApplicationFirewallPolicyLink: null
        }
      }
    ]
    backendPools: [
      {
        name: 'backendPool'
        properties: {
          backends: backends
        }
      }
    ]
    routingRules: [
      {
        name: 'defaultRouting'
        properties: {
          enabledState: 'Enabled'
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', name, 'frontendEndpoint')
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            customForwardingPath: null
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', name, 'backendPool')
            }
            cacheConfiguration: null
          }
        }
      }
      {
        name: 'httpUpgrade'
        properties: {
          enabledState: 'Enabled'
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', name, 'frontendEndpoint')
            }
          ]
          acceptedProtocols: [
            'Http'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectConfiguration'
            redirectType: 'Moved'
            redirectProtocol: 'HttpsOnly'
            customHost: null
            customPath: null
            customQueryString: null
          }
        }
      }
    ]
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Enabled'
      sendRecvTimeoutSeconds: 30
    }
  }
}

@description('The deployed Front Door resource.')
output resource resource = frontDoor
@description('ID for the deployed Front Door resource.')
output id string = frontDoor.id
@description('Name for the deployed Front Door resource.')
output name string = frontDoor.name
