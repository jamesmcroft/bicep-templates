@description('Name of the resource.')
param name string

@description('Name for the Container Apps Environment associated with the Dapr component.')
param containerAppsEnvironmentName string
@description('CRON schedule to configure for the binding.')
param schedule string
@description('Container App names for the scopes to configure for the binding.')
param scopes array = []

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = {
  name: name
  parent: containerAppsEnvironment
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    metadata: [
      {
        name: 'schedule'
        value: schedule
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
