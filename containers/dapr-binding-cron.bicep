@description('Name of the resource.')
param name string

@description('Name for the Container Apps Environment associated with the Dapr component.')
param containerAppsEnvironmentName string
@description('CRON schedule to configure for the binding.')
param schedule string
@description('Container App names for the scopes to configure for the binding.')
param scopes array = []

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
    name: containerAppsEnvironmentName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
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
