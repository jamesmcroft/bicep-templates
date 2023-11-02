targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the workload which is used to generate a short unique hash used in all resources.')
param workloadName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Name of the resource group. If empty, a unique name will be generated.')
param resourceGroupName string = ''

@description('Tags for all resources.')
param tags object = {}

@description('Name of the Storage Account. If empty, a unique name will be generated.')
param storageAccountName string = ''
@description('Name of the Storage File Service. If empty, a unique name will be generated.')
param storageFileServiceName string = ''
@description('Name of the Storage File Share. If empty, a unique name will be generated.')
param storageFileShareName string = ''

var abbrs = loadJsonContent('../abbreviations.json')
var roles = loadJsonContent('../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}${workloadName}'
  location: location
  tags: tags
}

module storageAccount '../storage/storage-account.bicep' = {
  name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageAccount}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageAccount}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard_LRS'
    }
  }
}

module storageFileService '../storage/storage-file-service.bicep' = {
  name: !empty(storageFileServiceName) ? storageFileServiceName : '${abbrs.fileService}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(storageFileServiceName) ? storageFileServiceName : '${abbrs.fileService}${resourceToken}'
    storageAccountName: storageAccount.outputs.name
  }
}

module storageFileShare '../storage/storage-file-share.bicep' = {
  name: !empty(storageFileShareName) ? storageFileShareName : '${abbrs.fileShare}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(storageFileShareName) ? storageFileShareName : '${abbrs.fileShare}${resourceToken}'
    storageAccountName: storageAccount.outputs.name
    fileServiceName: storageFileService.outputs.name
  }
}
