import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for Event Hub Namespace.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'Basic' | 'Premium' | 'Standard'
}

@description('Event Hub Namespace SKU. Defaults to Basic.')
param sku skuInfo = {
  name: 'Basic'
}
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
  'SecuredByPerimeter'
])
param publicNetworkAccess string = 'Enabled'
@description('Whether to enable auto-inflate. Defaults to False.')
param isAutoInflateEnabled bool = false
@description('The maximum throughput units for the namespace. Defaults to 0.')
param maximumThroughputUnits int = 0
@description('Value indicating whether the namespace is zone-redundant. Defaults to false.')
param zoneRedundant bool = false
@description('Whether to disable local (key-based) authentication. Defaults to true.')
param disableLocalAuth bool = true
@description('Role assignments to create for the Document Intelligence instance.')
param roleAssignments roleAssignmentInfo[] = []

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku.name
    tier: sku.name
  }
  properties: {
    isAutoInflateEnabled: isAutoInflateEnabled
    maximumThroughputUnits: maximumThroughputUnits
    publicNetworkAccess: publicNetworkAccess
    zoneRedundant: zoneRedundant
    disableLocalAuth: disableLocalAuth
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(eventHubNamespace.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: eventHubNamespace
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: 'ServicePrincipal'
    }
  }
]

@description('The deployed Event Hub Namespace resource.')
output resource resource = eventHubNamespace
@description('ID for the deployed Event Hub Namespace resource.')
output id string = eventHubNamespace.id
@description('Name for the deployed Event Hub Namespace resource.')
output name string = eventHubNamespace.name
