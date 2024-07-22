@description('Name of the resource.')
param name string

@description('Name for the Storage Account associated with the table.')
param storageAccountName string

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  name: '${storageAccountName}/default/${name}'
}

@description('The deployed Storage table resource.')
output resource resource = table
@description('ID for the deployed Storage table resource.')
output id string = table.id
@description('Name for the deployed Storage table resource.')
output name string = table.name
