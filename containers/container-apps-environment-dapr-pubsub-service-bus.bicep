@description('Name of the resource.')
param name string

@export()
@description('Information about the configuration for the Service Bus.')
type serviceBusConfigInfo = {
  @description('The timeout in seconds.')
  timeoutInSec: string
  @description('The initial retry interval in milliseconds for publishing.')
  publishInitialRetryInternalInMs: string
  @description('The maximum number of retries for publishing.')
  publishMaxRetries: string
}

@description('Name for the Container Apps Environment associated with the Dapr component.')
param containerAppsEnvironmentName string
@description('Name for the Service Bus Namespace associated with the Dapr component.')
param serviceBusNamespaceName string
@description('Client ID for the Managed Identity associated with the Dapr component.')
param identityClientId string
@description('Service Bus configuration for the Dapr component. Defaults to 60 seconds for the timeout, 1000 milliseconds for the initial retry interval, and 5 retries for the maximum number of retries.')
param serviceBusConfig serviceBusConfigInfo = {
  timeoutInSec: '60'
  publishInitialRetryInternalInMs: '1000'
  publishMaxRetries: '5'
}
@description('Container App names for the scopes to configure for the Dapr component.')
param scopes array = []

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = {
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
        value: listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', '2021-11-01').primaryConnectionString
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
