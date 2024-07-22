@description('Name of the resource.')
param name string

@description('Name for the Storage Account associated with the queue.')
param storageAccountName string

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  name: '${storageAccountName}/default/${name}'
  properties: {
    metadata: {}
  }
}

@description('The deployed Storage queue resource.')
output resource resource = queue
@description('ID for the deployed Storage queue resource.')
output id string = queue.id
@description('Name for the deployed Storage queue resource.')
output name string = queue.name
