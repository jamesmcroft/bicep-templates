@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type customDomainConfigInfo = {
    @description('Name of the custom domain.')
    dnsSuffix: string
    @description('Value of the custom domain certificate.')
    certificateValue: string
    @description('Password for the custom domain certificate.')
    certificatePassword: string
}

type vnetConfigInfo = {
    @description('CIDR notation IP range assigned to the Docker bridge network.')
    dockerBridgeCidr: string
    @description('Resource ID of a subnet for infrastructure components.')
    infrastructureSubnetId: string
    @description('Value indicating whether the environment only has an internal load balancer.')
    internal: bool
    @description('IP range in CIDR notation that can be reserved for environment infrastructure IP addresses.')
    platformReservedCidr: string
    @description('IP address from the IP range that will be reserved for the internal DNS server.')
    platformReservedDnsIP: string
}

type logAnalyticsConfigInfo = {
    customerId: string
    sharedKey: string?
}

@description('Log Analytics configuration to store application logs.')
param logAnalyticsConfig logAnalyticsConfigInfo = {
    customerId: ''
    sharedKey: ''
}
@description('Custom domain configuration for the environment.')
param customDomainConfig customDomainConfigInfo = {
    dnsSuffix: ''
    certificateValue: ''
    certificatePassword: ''
}
@description('Virtual network configuration for the environment.')
param vnetConfig vnetConfigInfo = {
    dockerBridgeCidr: ''
    infrastructureSubnetId: ''
    internal: false
    platformReservedCidr: ''
    platformReservedDnsIP: ''
}
@description('Value indicating whether the environment is zone-redundant. Defaults to false.')
param zoneRedundant bool = false

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
    name: name
    location: location
    tags: tags
    properties: {
        appLogsConfiguration: !empty(logAnalyticsConfig.sharedKey) ? {
            destination: 'log-analytics'
            logAnalyticsConfiguration: {
                customerId: logAnalyticsConfig.customerId
                sharedKey: logAnalyticsConfig.sharedKey
            }
        } : {}
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
