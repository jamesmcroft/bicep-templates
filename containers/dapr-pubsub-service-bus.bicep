@description('Name of the resource.')
param name string

type serviceBusConfigInfo = {
    timeoutInSec: string
    publishInitialRetryInternalInMs: string
    publishMaxRetries: string
}

@description('Name for the Container Apps Environment associated with the Dapr component.')
param containerAppsEnvironmentName string
@description('Connection string for the Service Bus Namespace associated with the Dapr component.')
param serviceBusConnectionString string
@description('Client ID for the Managed Identity associated with the Dapr component.')
param identityClientId string
@description('Service Bus configuration for the Dapr component.')
param serviceBusConfig serviceBusConfigInfo = {
    timeoutInSec: '60'
    publishInitialRetryInternalInMs: '1000'
    publishMaxRetries: '5'
}
@description('Container App names for the scopes to configure for the Dapr component.')
param scopes array = []

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
    name: containerAppsEnvironmentName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
    name: name
    parent: containerAppsEnvironment
    properties: {
        componentType: 'pubsub.azure.servicebus'
        version: 'v1'
        ignoreErrors: false
        initTimeout: '5s'
        metadata: [
            {
                name: 'connectionString'
                value: serviceBusConnectionString
            }
            {
                name: 'azureClientId'
                value: identityClientId
            }
            {
                name: 'timeoutInSec'
                value: serviceBusConfig.timeoutInSec
            }
            {
                name: 'publishInitialRetryInternalInMs'
                value: serviceBusConfig.publishInitialRetryInternalInMs
            }
            {
                name: 'publishMaxRetries'
                value: serviceBusConfig.publishMaxRetries
            }
        ]
        scopes: scopes
    }
}

@description('The deployed Dapr component resource.')
output resource resource = daprComponent
@description('ID for the deployed Dapr component resource.')
output id string = daprComponent.id
@description('Name for the deployed Dapr component resource.')
output name string = daprComponent.name
