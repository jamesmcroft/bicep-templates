@description('Name of the resource.')
param name string

@export()
@description('Information about the configuration of the storage account to be used by the Container Apps Environment.')
type storageConfigInfo = {
  @description('The access mode for the storage account.')
  accessMode: 'ReadWrite' | 'ReadOnly'
  @description('The storage account key.')
  accountKey: string
  @description('The storage account name.')
  accountName: string
  @description('The name of the file share.')
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
