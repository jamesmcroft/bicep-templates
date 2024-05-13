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

@description('Name of the Blob Container for grounding data. Defaults to data.')
param groundingDataBlobContainerName string = 'data'

var abbrs = loadJsonContent('../abbreviations.json')
var roles = loadJsonContent('../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.managementGovernance.resourceGroup}${workloadName}'
  location: location
  tags: union(tags, {})
}

module managedIdentity '../security/managed-identity.bicep' = {
  name: '${abbrs.security.managedIdentity}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.security.managedIdentity}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

resource keyVaultAdministrator 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.security.keyVaultAdministrator
}

module keyVault '../security/key-vault.bicep' = {
  name: '${abbrs.security.keyVault}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.security.keyVault}${resourceToken}'
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

resource cognitiveServicesOpenAIContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesOpenAIContributor
}

resource cognitiveServicesOpenAIUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesOpenAIUser
}

var completionsModelDeploymentName = 'gpt-35-turbo'
var embeddingModelDeploymentName = 'text-embedding-ada-002'

module openAI '../ai_ml/openai.bicep' = {
  name: '${abbrs.ai.openAIService}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.openAIService}${resourceToken}'
    location: location
    tags: union(tags, {})
    deployments: [
      {
        name: completionsModelDeploymentName
        model: {
          format: 'OpenAI'
          name: 'gpt-35-turbo'
          version: '1106'
        }
        sku: {
          name: 'Standard'
          capacity: 30
        }
      }
      {
        name: embeddingModelDeploymentName
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
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: cognitiveServicesOpenAIContributor.id
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: cognitiveServicesOpenAIUser.id
      }
    ]
  }
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.storage.storageBlobDataContributor
}

module storageAccount '../storage/storage-account.bicep' = {
  name: '${abbrs.storage.storageAccount}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.storage.storageAccount}${resourceToken}'
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

module groundingDataBlobContainer '../storage/storage-blob-container.bicep' = {
  name: groundingDataBlobContainerName
  scope: resourceGroup
  params: {
    name: groundingDataBlobContainerName
    storageAccountName: storageAccount.outputs.name
  }
}

module aiSearch '../ai_ml/ai-search.bicep' = {
  name: '${abbrs.ai.aiSearch}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.aiSearch}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

output subscriptionInfo object = {
  id: subscription().subscriptionId
  tenantId: subscription().tenantId
}

output resourceGroupInfo object = {
  id: resourceGroup.id
  name: resourceGroup.name
  location: resourceGroup.location
  workloadName: workloadName
}

output managedIdentityInfo object = {
  id: managedIdentity.outputs.id
  name: managedIdentity.outputs.name
  principalId: managedIdentity.outputs.principalId
  clientId: managedIdentity.outputs.clientId
}

output keyVaultInfo object = {
  id: keyVault.outputs.id
  name: keyVault.outputs.name
  uri: keyVault.outputs.uri
}

output openAIInfo object = {
  id: openAI.outputs.id
  name: openAI.outputs.name
  endpoint: openAI.outputs.endpoint
  host: openAI.outputs.host
  completionsModelDeploymentName: completionsModelDeploymentName
  embeddingModelDeploymentName: embeddingModelDeploymentName
}

output storageAccountInfo object = {
  id: storageAccount.outputs.id
  name: storageAccount.outputs.name
  groundingDataBlobContainerName: groundingDataBlobContainer.outputs.name
}

output aiSearchInfo object = {
  id: aiSearch.outputs.id
  name: aiSearch.outputs.name
}
