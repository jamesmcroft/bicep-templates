@export()
@description('Information about the Front Door Endpoint routes.')
type routeInfo = {
  @description('Name of the route.')
  name: string
  @description('Name of the origin group associated with the route.')
  originGroupName: string
  @description('Protocols supported by the route.')
  supportedProtocols: ('Http' | 'Https')[]
  @description('Patterns to match for the route.')
  patternsToMatch: string[]
  @description('Forwarding protocol for the route.')
  forwardingProtocol: 'MatchRequest' | 'HttpOnly' | 'HttpsOnly'
  @description('Whether to link to the default domain.')
  linkToDefaultDomain: 'Enabled' | 'Disabled'
  @description('Whether to redirect to HTTPS.')
  httpsRedirect: 'Enabled' | 'Disabled'
  @description('Whether the route is enabled.')
  enabledState: 'Enabled' | 'Disabled'
}

@export()
@description('Information about the Front Door Endpoint.')
type endpointInfo = {
  @description('Name of the Endpoint.')
  name: string
  @description('Routes associated with the Endpoint.')
  routes: routeInfo[]
}

@description('Name of the Front Door associated with the Endpoint.')
param frontDoorName string
@description('Endpoint information.')
param endpoint endpointInfo

resource frontDoor 'Microsoft.Cdn/profiles@2024-05-01-preview' existing = {
  name: frontDoorName
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-05-01-preview' = {
  name: endpoint.name
  parent: frontDoor
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }

  resource frontDoorRoute 'routes@2024-05-01-preview' = [
    for route in endpoint.routes: {
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
    }
  ]
}

@description('The deployed Front Door Endpoint resource.')
output resource resource = frontDoorEndpoint
@description('ID for the deployed Front Door Endpoint resource.')
output id string = frontDoorEndpoint.id
@description('Name for the deployed Front Door Endpoint resource.')
output name string = frontDoorEndpoint.name
