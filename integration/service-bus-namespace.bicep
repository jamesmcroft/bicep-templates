import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for Service Bus Namespace.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'Basic' | 'Premium' | 'Standard'
}

@description('Service Bus Namespace SKU. Defaults to Basic.')
param sku skuInfo = {
  name: 'Basic'
}
@description('Value indicating whether the namespace is zone-redundant. Defaults to false.')
param zoneRedundant bool = false
@description('Whether to disable local (key-based) authentication. Defaults to true.')
param disableLocalAuth bool = true
@description('Role assignments to create for the Service Bus Namespace.')
param roleAssignments roleAssignmentInfo[] = []

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    disableLocalAuth: disableLocalAuth
    zoneRedundant: zoneRedundant
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(serviceBusNamespace.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: serviceBusNamespace
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: 'ServicePrincipal'
    }
  }
]

@description('The deployed Service Bus Namespace resource.')
output resource resource = serviceBusNamespace
@description('ID for the deployed Service Bus Namespace resource.')
output id string = serviceBusNamespace.id
@description('Name for the deployed Service Bus Namespace resource.')
output name string = serviceBusNamespace.name
