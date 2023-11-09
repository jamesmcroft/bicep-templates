import * as originGroupTypes from 'front-door-origin-group.bicep'
import * as endpointTypes from 'front-door-endpoint.bicep'

@description('Name of the resource.')
param name string
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
  name: 'Standard_AzureFrontDoor' | 'Premium_AzureFrontDoor'
}

@description('Front Door SKU. Defaults to Standard.')
param sku skuInfo = {
  name: 'Standard_AzureFrontDoor'
}
@description('Endpoints for the Front Door resource.')
param endpoints endpointTypes.endpointInfo[]
@description('Origin groups for the Front Door resource.')
param originGroups originGroupTypes.originGroupInfo[]

resource frontDoor 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: name
  location: 'global'
  tags: tags
  sku: sku
}

module originGroup 'front-door-origin-group.bicep' = [for originGroup in originGroups: {
  name: originGroup.name
  params: {
    frontDoorName: frontDoor.name
    originGroup: originGroup
  }
}]

module endpoint 'front-door-endpoint.bicep' = [for endpoint in endpoints: {
  name: endpoint.name
  params: {
    frontDoorName: frontDoor.name
    endpoint: endpoint
  }
  dependsOn: [
    originGroup
  ]
}]

@description('The deployed Front Door resource.')
output resource resource = frontDoor
@description('ID for the deployed Front Door resource.')
output id string = frontDoor.id
@description('Name for the deployed Front Door resource.')
output name string = frontDoor.name
