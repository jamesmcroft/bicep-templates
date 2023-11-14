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

@description('Name of the Managed Identity. If empty, a unique name will be generated.')
param managedIdentityName string = ''
@description('Name of the OpenAI Service (Cognitive Services). If empty, a unique name will be generated.')
param openAIName string = ''
@description('Name of the Storage Account. If empty, a unique name will be generated.')
param storageAccountName string = ''
@description('Name of the Key Vault. If empty, a unique name will be generated.')
param keyVaultName string = ''
@description('Name of the Cognitive Search Service. If empty, a unique name will be generated.')
param cognitiveSearchName string = ''
@description('Name of the Blob Container for grounding data. Defaults to documents.')
param blobContainerName string = 'documents'

var abbrs = loadJsonContent('../abbreviations.json')
var roles = loadJsonContent('../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
    name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}${workloadName}'
    location: location
    tags: tags
}

module managedIdentity '../security/managed-identity.bicep' = {
    name: !empty(managedIdentityName) ? managedIdentityName : '${abbrs.managedIdentity}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(managedIdentityName) ? managedIdentityName : '${abbrs.managedIdentity}${resourceToken}'
        location: location
        tags: union(tags, {})
    }
}

resource keyVaultAdministrator 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup
    name: roles.keyVaultAdministrator
}

module keyVault '../security/key-vault.bicep' = {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVault}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVault}${resourceToken}'
        location: location
        tags: union(tags, {})
        roleAssignments: [
            {
                principalId: managedIdentity.outputs.principalId
                roleDefinitionId: keyVaultAdministrator.id
            }
        ]
    }
}

module openAI '../ai_ml/cognitive-services.bicep' = {
    name: !empty(openAIName) ? openAIName : '${abbrs.openAI}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(openAIName) ? openAIName : '${abbrs.openAI}${resourceToken}'
        location: location
        tags: union(tags, {})
        sku: {
            name: 'S0'
        }
        kind: 'OpenAI'
        deployments: [
            {
                name: 'gpt-35-turbo'
                model: {
                    format: 'OpenAI'
                    name: 'gpt-35-turbo'
                    version: '0301'
                }
                sku: {
                    name: 'Standard'
                    capacity: 1
                }
            }
            {
                name: 'text-embedding-ada-002'
                model: {
                    format: 'OpenAI'
                    name: 'text-embedding-ada-002'
                    version: '2'
                }
                sku: {
                    name: 'Standard'
                    capacity: 1
                }
            }
        ]
        keyVaultSecrets: {
            name: keyVault.outputs.name
            secrets: [
                {
                    property: 'PrimaryKey'
                    name: 'OPENAI-API-KEY'
                }
            ]
        }
    }
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup
    name: roles.storageBlobDataContributor
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
        roleAssignments: [
            {
                principalId: managedIdentity.outputs.principalId
                roleDefinitionId: storageBlobDataContributor.id
            }
        ]
        blobContainerRetention: {
            allowPermanentDelete: false
            enabled: true
            days: 7
        }
    }
}

module blobContainer '../storage/storage-blob-container.bicep' = {
    name: blobContainerName
    scope: resourceGroup
    params: {
        name: blobContainerName
        storageAccountName: storageAccount.outputs.name
    }
}

module cognitiveSearch '../ai_ml/cognitive-search.bicep' = {
    name: !empty(cognitiveSearchName) ? cognitiveSearchName : '${abbrs.cognitiveSearch}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(cognitiveSearchName) ? cognitiveSearchName : '${abbrs.cognitiveSearch}${resourceToken}'
        location: location
        tags: union(tags, {})
    }
}
