@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('Admin username for the SQL Server resource.')
param adminUsername string
@description('Admin password for the SQL Server resource.')
@secure()
param adminPassword string
@description('Whether to allow Azure IPs to access the SQL server resource. Defaults to true.')
param allowAzureIps bool = true

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
    name: name
    location: location
    tags: tags
    properties: {
        administratorLogin: adminUsername
        administratorLoginPassword: adminPassword
    }
}

resource sqlServerAzureFirewallRules 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if (allowAzureIps) {
    parent: sqlServer
    name: 'AllowAllWindowsAzureIps'
    properties: {
        startIpAddress: '0.0.0.0'
        endIpAddress: '0.0.0.0'
    }
}

@description('The deployed SQL Server resource.')
output resource resource = sqlServer
@description('ID for the deployed SQL Server resource.')
output id string = sqlServer.id
@description('Name for the deployed SQL Server resource.')
output name string = sqlServer.name
