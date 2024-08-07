@description('Name of the resource. Defaults to default')
param name string = 'default'

@description('Name for the Storage Account associated with the file service.')
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  name: name
  parent: storageAccount
}

@description('The deployed Storage file service resource.')
output resource resource = fileService
@description('ID for the deployed Storage file service resource.')
output id string = fileService.id
@description('Name for the deployed Storage file service resource.')
output name string = fileService.name
