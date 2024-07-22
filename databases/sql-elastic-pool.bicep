@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for SQL Elastic Pool.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'BasicPool' | 'Standard' | 'Premium' | 'GP_Gen5' | 'BC_Gen5'
  @description('Capacity of the SKU.')
  capacity: int?
}

@export()
@description('Information about the per database configuration for the SQL Elastic Pool.')
type perDatabaseConfigInfo = {
  @description('Minimum capacity.')
  minCapacity: int
  @description('Maximum capacity.')
  maxCapacity: int
}

@description('Name for the SQL Server associated with the SQL Elastic Pool resource.')
param sqlServerName string
@description('SQL Elastic Pool SKU. Defaults to BasicPool, capacity 50.')
param sku skuInfo = {
  name: 'BasicPool'
  capacity: 50
}
@description('Per database configuration for the SQL Elastic Pool resource. Defaults to min 0, max 5.')
param perDatabaseConfig perDatabaseConfigInfo = {
  minCapacity: 0
  maxCapacity: 5
}
@description('Maximum storage capacity (bytes) for the SQL Elastic Pool resource. Defaults to 5242880000.')
param maxStorageSizeCapacity int = 5242880000
@description('Whether replicas are spread across availability zones for the SQL Elastic Pool resource. Defaults to false.')
param zoneRedundant bool = false
@description('SQL Elastic Pool License. Defaults to LicenseIncluded.')
@allowed([
  'LicenseIncluded'
  'BasePrice'
])
param licenseType string = 'LicenseIncluded'

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlServerName
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2023-08-01-preview' = {
  parent: sqlServer
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    perDatabaseSettings: perDatabaseConfig
    maxSizeBytes: maxStorageSizeCapacity
    zoneRedundant: zoneRedundant
    licenseType: licenseType
  }
}

@description('The deployed SQL Elastic Pool resource.')
output resource resource = elasticPool
@description('ID for the deployed SQL Elastic Pool resource.')
output id string = elasticPool.id
@description('Name for the deployed SQL Elastic Pool resource.')
output name string = elasticPool.name
