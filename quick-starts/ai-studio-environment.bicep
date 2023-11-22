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

@description('Value indicating whether the deployment is new or existing.')
@allowed([
    'new'
    'existing'
])
param newOrExisting string = 'new'

@description('Name of the Managed Identity. If empty, a unique name will be generated.')
param managedIdentityName string = ''
@description('Name of the Storage Account. If empty, a unique name will be generated.')
param storageAccountName string = ''
@description('Name of the Key Vault. If empty, a unique name will be generated.')
param keyVaultName string = ''
@description('Name of the Log Analytics Workspace. If empty, a unique name will be generated.')
param logAnalyticsWorkspaceName string = ''
@description('Name of the Application Insights. If empty, a unique name will be generated.')
param applicationInsightsName string = ''
@description('Name of the Container Registry. If empty, a unique name will be generated.')
param containerRegistryName string = ''
@description('Name of the AI Workspace. If empty, a unique name will be generated.')
param aiWorkspaceName string = ''
@description('Name of the AI Services (Cognitive Services). If empty, a unique name will be generated.')
param aiServiceName string = ''

var abbrs = loadJsonContent('../abbreviations.json')
var roles = loadJsonContent('../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
    name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}${workloadName}'
    location: location
    tags: union(tags, {})
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

module resourceGroupContributorAssignment '../security/managed-identity-resourcegroup-role.bicep' = {
    name: '${managedIdentity.name}-resourcegroup-contributor'
    scope: resourceGroup
    params: {
        identityPrincipalId: managedIdentity.outputs.principalId
        resourceId: resourceGroup.id
        roleDefinitionId: roles.contributor
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
    }
}

resource keyVaultContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup
    name: roles.contributor
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
                roleDefinitionId: keyVaultContributor.id
            }
            {
                principalId: managedIdentity.outputs.principalId
                roleDefinitionId: keyVaultAdministrator.id
            }
        ]
    }
}

module logAnalyticsWorkspace '../management_governance/log-analytics-workspace.bicep' = {
    name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.logAnalyticsWorkspace}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.logAnalyticsWorkspace}${resourceToken}'
        location: location
        tags: union(tags, {})
        applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.applicationInsights}${resourceToken}'
    }
}

resource containerRegistryPush 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup
    name: roles.acrPush
}

resource containerRegistryPull 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup
    name: roles.acrPull
}

module containerRegistry '../containers/container-registry.bicep' = {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistry}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistry}${resourceToken}'
        location: location
        tags: union(tags, {})
        sku: {
            name: 'Basic'
        }
        adminUserEnabled: true
        roleAssignments: [
            {
                principalId: managedIdentity.outputs.principalId
                roleDefinitionId: containerRegistryPush.id
            }
            {
                principalId: managedIdentity.outputs.principalId
                roleDefinitionId: containerRegistryPull.id
            }
        ]
    }
}

resource openAIContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup
    name: roles.cognitiveServicesOpenAIContributor
}

resource openAIUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup
    name: roles.cognitiveServicesOpenAIUser
}

module aiServices '../ai_ml/ai-service.bicep' = {
    name: !empty(aiServiceName) ? aiServiceName : '${abbrs.aiServices}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(aiServiceName) ? aiServiceName : '${abbrs.aiServices}${resourceToken}'
        location: location
        tags: union(tags, {})
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
        roleAssignments: [
            {
                principalId: managedIdentity.outputs.principalId
                roleDefinitionId: openAIContributor.id
            }
            {
                principalId: managedIdentity.outputs.principalId
                roleDefinitionId: openAIUser.id
            }
        ]
    }
}

module aiWorkspace '../ai_ml/ai-workspace.bicep' = {
    name: !empty(aiWorkspaceName) ? aiWorkspaceName : '${abbrs.aiWorkspace}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(aiWorkspaceName) ? aiWorkspaceName : '${abbrs.aiWorkspace}${resourceToken}'
        location: location
        tags: union(tags, {})
        identityId: managedIdentity.outputs.id
        storageAccountId: storageAccount.outputs.id
        keyVaultId: keyVault.outputs.id
        applicationInsightsId: logAnalyticsWorkspace.outputs.applicationInsightsId
        containerRegistryId: containerRegistry.outputs.id
    }
}

module aiWorkspaceOpenAIEndpoint '../ai_ml/ai-workspace-endpoint.bicep' = if(newOrExisting == 'new') {
    name: '${aiWorkspace.name}-openai'
    scope: resourceGroup
    params: {
        workspaceName: aiWorkspace.outputs.name
        endpoint: {
            name: 'Azure.OpenAI'
            endpointResourceId: aiServices.outputs.id
        }
    }
}

module aiWorkspaceContentSafetyEndpoint '../ai_ml/ai-workspace-endpoint.bicep' = if(newOrExisting == 'new') {
    name: '${aiWorkspace.name}-contentsafety'
    scope: resourceGroup
    params: {
        workspaceName: aiWorkspace.outputs.name
        endpoint: {
            name: 'Azure.ContentSafety'
            endpointResourceId: aiServices.outputs.id
        }
    }
}

module aiWorkspaceSpeechEndpoint '../ai_ml/ai-workspace-endpoint.bicep' = if(newOrExisting == 'new') {
    name: '${aiWorkspace.name}-speech'
    scope: resourceGroup
    params: {
        workspaceName: aiWorkspace.outputs.name
        endpoint: {
            name: 'Azure.Speech'
            endpointResourceId: aiServices.outputs.id
        }
    }
}
