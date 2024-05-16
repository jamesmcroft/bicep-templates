import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for AI Search.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'free' | 'basic' | 'standard' | 'standard2' | 'standard3' | 'storage_optimized_l1' | 'storage_optimized_l2'
}

@description('AI Search SKU. Defaults to basic.')
param sku skuInfo = {
  name: 'basic'
}
@description('Number of replicas to distribute search workloads. Defaults to 1.')
@minValue(1)
@maxValue(12)
param replicaCount int = 1
@description('Number of partitions for scaling of document count and faster indexing by sharding your index over multiple search units.')
@allowed([
  1
  2
  3
  4
  6
  12
])
param partitionCount int = 1
@description('Enable a single, high density partition that allows up to 1000 indexes, which is much higher than the maximum indexes allowed for any other SKU (only for standard3).')
@allowed([
  'default'
  'highDensity'
])
param hostingMode string = 'default'
@description('Role assignments to create for the AI Search instance.')
param roleAssignments roleAssignmentInfo[] = []

resource aiSearch 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: hostingMode
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http403'
      }
    }
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(aiSearch.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: aiSearch
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

@description('The deployed AI Search resource.')
output resource resource = aiSearch
@description('ID for the deployed AI Search resource.')
output id string = aiSearch.id
@description('Name for the deployed AI Search resource.')
output name string = aiSearch.name
