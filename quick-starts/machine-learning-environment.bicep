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
@description('Name of the Machine Learning Workspace. If empty, a unique name will be generated.')
param machineLearningWorkspaceName string = ''

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

module storageBlobContributorAuth '../security/managed-identity-role.bicep' = {
    name: '${managedIdentity.name}-${storageAccount.name}-blobcontributor'
    scope: resourceGroup
    params: {
        resourceId: storageAccount.outputs.id
        identityPrincipalId: managedIdentity.outputs.principalId
        roleDefinitionId: roles.storageBlobDataContributor
    }
    dependsOn: [
        storageAccount
        managedIdentity
    ]
}

module keyVault '../security/key-vault.bicep' = {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVault}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVault}${resourceToken}'
        location: location
        tags: union(tags, {})
    }
}

module keyVaultContributorAuth '../security/managed-identity-role.bicep' = {
    name: '${managedIdentity.name}-${keyVault.name}-contributor'
    scope: resourceGroup
    params: {
        resourceId: keyVault.outputs.id
        identityPrincipalId: managedIdentity.outputs.principalId
        roleDefinitionId: roles.contributor
    }
    dependsOn: [
        keyVault
        managedIdentity
    ]
}

module keyVaultAdministratorAuth '../security/managed-identity-role.bicep' = {
    name: '${managedIdentity.name}-${keyVault.name}-administrator'
    scope: resourceGroup
    params: {
        resourceId: keyVault.outputs.id
        identityPrincipalId: managedIdentity.outputs.principalId
        roleDefinitionId: roles.keyVaultAdministrator
    }
    dependsOn: [
        keyVault
        managedIdentity
    ]
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
    }
}

module containerRegistryPushAuth '../security/managed-identity-role.bicep' = {
    name: '${managedIdentity.name}-${containerRegistry.name}-push'
    scope: resourceGroup
    params: {
        resourceId: containerRegistry.outputs.id
        identityPrincipalId: managedIdentity.outputs.principalId
        roleDefinitionId: roles.acrPush
    }
    dependsOn: [
        containerRegistry
        managedIdentity
    ]
}

module containerRegistryPullAuth '../security/managed-identity-role.bicep' = {
    name: '${managedIdentity.name}-${containerRegistry.name}-pull'
    scope: resourceGroup
    params: {
        resourceId: containerRegistry.outputs.id
        identityPrincipalId: managedIdentity.outputs.principalId
        roleDefinitionId: roles.acrPull
    }
    dependsOn: [
        containerRegistry
        managedIdentity
    ]
}

module machineLearningWorkspace '../ai_ml/machine-learning-workspace.bicep' = {
    name: !empty(machineLearningWorkspaceName) ? machineLearningWorkspaceName : '${abbrs.machineLearningWorkspace}${resourceToken}'
    scope: resourceGroup
    params: {
        name: !empty(machineLearningWorkspaceName) ? machineLearningWorkspaceName : '${abbrs.machineLearningWorkspace}${resourceToken}'
        location: location
        tags: union(tags, {})
        identityId: managedIdentity.outputs.id
        storageAccountId: storageAccount.outputs.id
        keyVaultId: keyVault.outputs.id
        applicationInsightsId: logAnalyticsWorkspace.outputs.applicationInsightsId
        containerRegistryId: containerRegistry.outputs.id
    }
}
