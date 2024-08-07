@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for SQL Database.')
type skuInfo = {
  @description('Name of the SKU.')
  name:
    | 'Basic'
    | 'S0'
    | 'S1'
    | 'S2'
    | 'S3'
    | 'S4'
    | 'S6'
    | 'S7'
    | 'S9'
    | 'S12'
    | 'P1'
    | 'P2'
    | 'P4'
    | 'P6'
    | 'P11'
    | 'P15'
}

@description('Name for the SQL Server associated with the SQL Database.')
param sqlServerName string
@description('SQL Database SKU. Defaults to Basic.')
param sku skuInfo = {
  name: 'Basic'
}
@description('ID for the SQL Elastic Pool associated with the SQL Database.')
param sqlServerElasticPoolId string = ''

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    elasticPoolId: !empty(sqlServerElasticPoolId) ? sqlServerElasticPoolId : ''
  }
}

@description('The deployed SQL Database resource.')
output resource resource = sqlDatabase
@description('ID for the deployed SQL Database resource.')
output id string = sqlDatabase.id
@description('Name for the deployed SQL Database resource.')
output name string = sqlDatabase.name
@description('Connection string (without credentials) for the deployed SQL Database resource.')
output connectionString string = 'Server=tcp:${sqlServerName}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${name};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30'
