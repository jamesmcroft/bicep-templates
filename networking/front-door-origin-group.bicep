@export()
type originInfo = {
  name: string
  hostName: string
  httpPort: int
  httpsPort: int
  originHostHeader: string
  priority: int
  weight: int
}

@export()
type originGroupLoadBalancingSettingsInfo = {
  sampleSize: int
  successfulSamplesRequired: int
  additionalLatencyInMilliseconds: int
}

@export()
type originGroupHealthProbeSettingsInfo = {
  probePath: string
  probeProtocol: 'Http' | 'Https'
  probeIntervalInSeconds: int
  probeRequestType: 'GET' | 'HEAD'
}

@export()
type originGroupInfo = {
  name: string
  origins: originInfo[]
  loadBalancingSettings: originGroupLoadBalancingSettingsInfo
  healthProbeSettings: originGroupHealthProbeSettingsInfo
}

@description('Name of the Front Door associated with the Origin Group.')
param frontDoorName string
@description('Origin group information.')
param originGroup originGroupInfo

resource frontDoor 'Microsoft.Cdn/profiles@2021-06-01' existing = {
  name: frontDoorName
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: originGroup.name
  parent: frontDoor
  properties: {
    healthProbeSettings: originGroup.healthProbeSettings
    loadBalancingSettings: originGroup.loadBalancingSettings
  }

  resource frontDoorOrigin 'origins@2021-06-01' = [for origin in originGroup.origins: {
    name: origin.name
    properties: {
      hostName: origin.hostName
      httpPort: origin.httpPort
      httpsPort: origin.httpsPort
      originHostHeader: origin.originHostHeader
      priority: origin.priority
      weight: origin.weight
    }
  }]
}

@description('The deployed Front Door Origin Group resource.')
output resource resource = frontDoorOriginGroup
@description('ID for the deployed Front Door Origin Group resource.')
output id string = frontDoorOriginGroup.id
@description('Name for the deployed Front Door Origin Group resource.')
output name string = frontDoorOriginGroup.name
