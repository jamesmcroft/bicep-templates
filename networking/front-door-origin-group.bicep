@export()
@description('Information about the origin of the Front Door Origin Group.')
type originInfo = {
  @description('Name of the origin.')
  name: string
  @description('Host name of the origin.')
  hostName: string
  @description('HTTP port of the origin.')
  httpPort: int
  @description('HTTPS port of the origin.')
  httpsPort: int
  @description('Origin host header.')
  originHostHeader: string
  @description('Priority of the origin.')
  priority: int
  @description('Weight of the origin.')
  weight: int
}

@export()
@description('Information about the load balancing settings of the Front Door Origin Group.')
type originGroupLoadBalancingSettingsInfo = {
  @description('Sample size for load balancing.')
  sampleSize: int
  @description('Successful samples required for load balancing.')
  successfulSamplesRequired: int
  @description('Additional latency in milliseconds.')
  additionalLatencyInMilliseconds: int
}

@export()
@description('Information about the health probe settings of the Front Door Origin Group.')
type originGroupHealthProbeSettingsInfo = {
  @description('Path of the probe.')
  probePath: string
  @description('Protocol of the probe.')
  probeProtocol: 'Http' | 'Https'
  @description('Interval in seconds for the probe.')
  probeIntervalInSeconds: int
  @description('HTTP method type of the probe.')
  probeRequestType: 'GET' | 'HEAD'
}

@export()
@description('Information about the origin group of the Front Door.')
type originGroupInfo = {
  @description('Name of the origin group.')
  name: string
  @description('List of origins.')
  origins: originInfo[]
  @description('Load balancing settings of the origin group.')
  loadBalancingSettings: originGroupLoadBalancingSettingsInfo
  @description('Health probe settings of the origin group.')
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

  resource frontDoorOrigin 'origins@2021-06-01' = [
    for origin in originGroup.origins: {
      name: origin.name
      properties: {
        hostName: origin.hostName
        httpPort: origin.httpPort
        httpsPort: origin.httpsPort
        originHostHeader: origin.originHostHeader
        priority: origin.priority
        weight: origin.weight
      }
    }
  ]
}

@description('The deployed Front Door Origin Group resource.')
output resource resource = frontDoorOriginGroup
@description('ID for the deployed Front Door Origin Group resource.')
output id string = frontDoorOriginGroup.id
@description('Name for the deployed Front Door Origin Group resource.')
output name string = frontDoorOriginGroup.name
