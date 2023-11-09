@export()
type routeInfo = {
  name: string
  originGroupName: string
  supportedProtocols: ('Http' | 'Https')[]
  patternsToMatch: string[]
  forwardingProtocol: 'MatchRequest' | 'HttpOnly' | 'HttpsOnly'
  linkToDefaultDomain: 'Enabled' | 'Disabled'
  httpsRedirect: 'Enabled' | 'Disabled'
  enabledState: 'Enabled' | 'Disabled'
}

@export()
type endpointInfo = {
  name: string
  routes: routeInfo[]
}

@description('Name of the Front Door associated with the Endpoint.')
param frontDoorName string
@description('Endpoint information.')
param endpoint endpointInfo

resource frontDoor 'Microsoft.Cdn/profiles@2021-06-01' existing = {
  name: frontDoorName
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: endpoint.name
  parent: frontDoor
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }

  resource frontDoorRoute 'routes@2021-06-01' = [for route in endpoint.routes: {
    name: route.name
    properties: {
      originGroup: {
        id: resourceId('Microsoft.Cdn/profiles/originGroups', frontDoorName, route.originGroupName)
      }
      supportedProtocols: route.supportedProtocols
      patternsToMatch: route.patternsToMatch
      forwardingProtocol: route.forwardingProtocol
      linkToDefaultDomain: route.linkToDefaultDomain
      httpsRedirect: route.httpsRedirect
      enabledState: route.enabledState
    }
  }]
}

@description('The deployed Front Door Endpoint resource.')
output resource resource = frontDoorEndpoint
@description('ID for the deployed Front Door Endpoint resource.')
output id string = frontDoorEndpoint.id
@description('Name for the deployed Front Door Endpoint resource.')
output name string = frontDoorEndpoint.name
