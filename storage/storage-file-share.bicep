@description('Name of the resource.')
param name string

@description('Name for the Storage Account associated with the file share.')
param storageAccountName string
@description('Name for the File Service associated with the file share.')
param fileServiceName string
@description('Access tier for the File Share. Defaults to Hot.')
@allowed([
    'Hot'
    'Cool'
    'Premium'
    'TransactionOptimized'
])
param accessTier string = 'Hot'

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
    name: '${storageAccountName}/${fileServiceName}'
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
    name: name
    parent: fileService
    properties: {
        accessTier: accessTier
        enabledProtocols: 'SMB'
        metadata: {}
        shareQuota: 5120
    }
}

@description('ID for the deployed Storage file share resource.')
output id string = fileShare.id
@description('Name for the deployed Storage file share resource.')
output name string = fileShare.name
