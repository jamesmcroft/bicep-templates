@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type logAnalyticsConfigInfo = {
    customerId: string
    sharedKey: string?
}

@description('Log Analytics configuration to store application logs.')
param logAnalyticsConfig logAnalyticsConfigInfo = {
    customerId: ''
    sharedKey: ''
}

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
    }
}

@description('The deployed Container Apps Environment resource.')
output resource resource = containerAppsEnvironment
@description('ID for the deployed Container Apps Environment resource.')
output id string = containerAppsEnvironment.id
@description('Name for the deployed Container Apps Environment resource.')
output name string = containerAppsEnvironment.name
