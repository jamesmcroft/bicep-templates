@description('Name of the resource.')
param name string

type storageConfigInfo = {
    accessMode: 'ReadWrite' | 'ReadOnly'
    accountKey: string
    accountName: string
    shareName: string
}

@description('Name for the Container Apps Environment associated with the storage.')
param containerAppsEnvironmentName string
@description('Storage configuration for the Container Apps Environment.')
param storageConfig storageConfigInfo

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
    name: containerAppsEnvironmentName
}

resource storage 'Microsoft.App/managedEnvironments/storages@2023-05-01' = {
    name: name
    parent: containerAppsEnvironment
    properties: {
        azureFile: storageConfig
    }
}

@description('The deployed Container Apps Storage resource.')
output resource resource = storage
@description('ID for the deployed Container Apps Storage resource.')
output id string = storage.id
@description('Name for the deployed Container Apps Storage resource.')
output name string = storage.name
