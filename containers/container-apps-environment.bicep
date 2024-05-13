@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('Information about the configuration for a custom domain in the environment.')
type customDomainConfigInfo = {
  @description('Name of the custom domain.')
  dnsSuffix: string
  @description('Value of the custom domain certificate.')
  certificateValue: string
  @description('Password for the custom domain certificate.')
  certificatePassword: string
}

@export()
@description('Information about the configuration for a virtual network in the environment.')
type vnetConfigInfo = {
  @description('Resource ID of a subnet for infrastructure components.')
  infrastructureSubnetId: string
  @description('Value indicating whether the environment only has an internal load balancer.')
  internal: bool
}

@description('Name of the Log Analytics Workspace to store application logs.')
param logAnalyticsWorkspaceName string
@description('Custom domain configuration for the environment.')
param customDomainConfig customDomainConfigInfo = {
  dnsSuffix: ''
  certificateValue: ''
  certificatePassword: ''
}
@description('Virtual network configuration for the environment.')
param vnetConfig vnetConfigInfo = {
  infrastructureSubnetId: ''
  internal: true
}
@description('Value indicating whether the environment is zone-redundant. Defaults to false.')
param zoneRedundant bool = false

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    customDomainConfiguration: !empty(customDomainConfig.dnsSuffix) ? customDomainConfig : {}
    vnetConfiguration: !empty(vnetConfig.infrastructureSubnetId) ? vnetConfig : {}
    zoneRedundant: zoneRedundant
  }
}

@description('The deployed Container Apps Environment resource.')
output resource resource = containerAppsEnvironment
@description('ID for the deployed Container Apps Environment resource.')
output id string = containerAppsEnvironment.id
@description('Name for the deployed Container Apps Environment resource.')
output name string = containerAppsEnvironment.name
@description('Default domain for the deployed Container Apps Environment resource.')
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
@description('Static IP for the deployed Container Apps Environment resource.')
output staticIp string = containerAppsEnvironment.properties.staticIp
