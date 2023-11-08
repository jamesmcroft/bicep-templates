@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
  name: 'free' | 'basic' | 'standard' | 'standard2' | 'standard3' | 'storage_optimized_l1' | 'storage_optimized_l2'
}

@description('Container Search SKU. Defaults to basic.')
param sku skuInfo = {
  name: 'basic'
}
@description('Number of replicates to distribute search workloads. Defaults to 1.')
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

resource search 'Microsoft.Search/searchServices@2022-09-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: hostingMode
  }
}

@description('The deployed Cognitive Search resource.')
output resource resource = search
@description('ID for the deployed Cognitive Search resource.')
output id string = search.id
@description('Name for the deployed Cognitive Search resource.')
output name string = search.name
