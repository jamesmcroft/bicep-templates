import { modelDeploymentInfo, raiPolicyInfo } from '../../ai_ml/ai-services.bicep'
import { identityInfo } from '../../security/managed-identity.bicep'

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the workload which is used to generate a short unique hash used in all resources.')
param workloadName string

@minLength(1)
@description('Primary location for all resources. AI Content Understanding is currently only available in the following regions: westus, swedencentral, australiaeast.')
@allowed([
  'westus'
  'swedencentral'
  'australiaeast'
])
param location string

@description('Name of the resource group. If empty, a unique name will be generated.')
param resourceGroupName string = ''

@description('Tags for all resources.')
param tags object = {}

@description('Responsible AI policies for the Azure AI Services instance.')
param raiPolicies raiPolicyInfo[] = [
  {
    name: workloadName
    mode: 'Blocking'
    prompt: {}
    completion: {}
  }
]

@description('Model deployments for the Azure AI Services instance.')
param aiServiceModelDeployments modelDeploymentInfo[] = [
  {
    name: 'gpt-4o'
    model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-11-20' }
    sku: { name: 'GlobalStandard', capacity: 10 }
    raiPolicyName: workloadName
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
]

@description('Identities to assign roles to.')
param identities identityInfo[] = []

var abbrs = loadJsonContent('../../abbreviations.json')
var roles = loadJsonContent('../../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource contributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.general.contributor
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.managementGovernance.resourceGroup}${workloadName}'
  location: location
  tags: union(tags, {})
}

var contributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: contributorRole.id
    principalType: identity.principalType
  }
]

module resourceGroupRoleAssignment '../../security/resource-group-role-assignment.bicep' = {
  name: '${resourceGroup.name}-role-assignment'
  scope: resourceGroup
  params: {
    roleAssignments: concat(contributorIdentityAssignments, [])
  }
}

resource keyVaultContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.security.keyVaultContributor
}

var keyVaultContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: keyVaultContributorRole.id
    principalType: identity.principalType
  }
]

module keyVault '../../security/key-vault.bicep' = {
  name: '${abbrs.security.keyVault}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.security.keyVault}${resourceToken}'
    location: location
    tags: union(tags, {})
    roleAssignments: concat(keyVaultContributorIdentityAssignments, [])
  }
}

module logAnalyticsWorkspace '../../management_governance/log-analytics-workspace.bicep' = {
  name: '${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

module applicationInsights '../../management_governance/application-insights.bicep' = {
  name: '${abbrs.managementGovernance.applicationInsights}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.managementGovernance.applicationInsights}${resourceToken}'
    location: location
    tags: union(tags, {})
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

resource cognitiveServicesUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesUser
}

resource cognitiveServicesContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesContributor
}

resource cognitiveServicesOpenAIContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesOpenAIContributor
}

resource cognitiveServicesOpenAIUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesOpenAIUser
}

var cognitiveServicesUserRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesUserRole.id
    principalType: identity.principalType
  }
]

var cognitiveServicesContributorRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesContributorRole.id
    principalType: identity.principalType
  }
]

var cognitiveServicesOpenAIUserRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesOpenAIUserRole.id
    principalType: identity.principalType
  }
]

var cognitiveServicesOpenAIContributorRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesOpenAIContributorRole.id
    principalType: identity.principalType
  }
]

module aiServices '../../ai_ml/ai-services.bicep' = {
  name: '${abbrs.ai.aiServices}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.aiServices}${resourceToken}'
    location: location
    tags: union(tags, {})
    raiPolicies: raiPolicies
    deployments: aiServiceModelDeployments
    roleAssignments: concat(
      cognitiveServicesUserRoleAssignments,
      cognitiveServicesContributorRoleAssignments,
      cognitiveServicesOpenAIUserRoleAssignments,
      cognitiveServicesOpenAIContributorRoleAssignments,
      []
    )
  }
}

// Require self-referencing role assignment for AI Services identity to access Azure OpenAI.
module aiServicesRoleAssignment '../../security/resource-role-assignment.json' = {
  name: '${abbrs.ai.aiServices}${resourceToken}-role-assignment'
  scope: resourceGroup
  params: {
    resourceId: aiServices.outputs.id
    roleAssignments: [
      {
        principalId: aiServices.outputs.principalId
        roleDefinitionId: cognitiveServicesUserRole.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Storage account roles required for using Prompt Flow in AI Hubs
resource storageAccountContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageAccountContributor
}

resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageBlobDataContributor
}

resource storageFileDataPrivilegedContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageFileDataPrivilegedContributor
}

resource storageTableDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageTableDataContributor
}

var storageAccountContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageAccountContributorRole.id
    principalType: identity.principalType
  }
]

var storageBlobDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageBlobDataContributorRole.id
    principalType: identity.principalType
  }
]

var storageFileDataPrivilegedContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageFileDataPrivilegedContributorRole.id
    principalType: identity.principalType
  }
]

var storageTableDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageTableDataContributorRole.id
    principalType: identity.principalType
  }
]

module storageAccount '../../storage/storage-account.bicep' = {
  name: '${abbrs.storage.storageAccount}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.storage.storageAccount}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard_LRS'
    }
    roleAssignments: concat(
      storageAccountContributorIdentityAssignments,
      storageBlobDataContributorIdentityAssignments,
      storageFileDataPrivilegedContributorIdentityAssignments,
      storageTableDataContributorIdentityAssignments,
      [
        {
          principalId: aiServices.outputs.principalId
          roleDefinitionId: storageBlobDataContributorRole.id
          principalType: 'ServicePrincipal'
        }
      ]
    )
  }
}

var contentUnderstandingContainerName = toLower(uniqueString(resourceToken, 'content-understanding'))
module contentUnderstandingContainer '../../storage/storage-blob-container.bicep' = {
  name: contentUnderstandingContainerName
  scope: resourceGroup
  params: {
    name: contentUnderstandingContainerName
    storageAccountName: storageAccount.outputs.name
  }
}

resource azureMLDataScientistRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.azureMLDataScientist
}

var azureMLDataScientistRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: azureMLDataScientistRole.id
    principalType: identity.principalType
  }
]

module aiHub '../../ai_ml/ai-hub.bicep' = {
  name: '${abbrs.ai.aiHub}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.aiHub}${resourceToken}'
    friendlyName: 'Hub - AI Content Understanding'
    descriptionInfo: 'Generated by the AI Content Understanding Quickstart'
    location: location
    tags: union(tags, {})
    storageAccountId: storageAccount.outputs.id
    keyVaultId: keyVault.outputs.id
    applicationInsightsId: applicationInsights.outputs.id
    aiServicesName: aiServices.outputs.name
    roleAssignments: concat(azureMLDataScientistRoleAssignments, [])
  }
}

module aiHubProject '../../ai_ml/ai-hub-project.bicep' = {
  name: '${abbrs.ai.aiHubProject}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.aiHubProject}${resourceToken}'
    friendlyName: 'Project - AI Content Understanding'
    descriptionInfo: 'Generated by the AI Content Understanding Quickstart'
    location: location
    tags: union(tags, {})
    aiHubName: aiHub.outputs.name
    roleAssignments: concat(azureMLDataScientistRoleAssignments, [])
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

output storageAccountInfo object = {
  id: storageAccount.outputs.id
  name: storageAccount.outputs.name
  contentUnderstandingContainerName: contentUnderstandingContainerName
}

output keyVaultInfo object = {
  id: keyVault.outputs.id
  name: keyVault.outputs.name
  uri: keyVault.outputs.uri
}

output logAnalyticsWorkspaceInfo object = {
  id: logAnalyticsWorkspace.outputs.id
  name: logAnalyticsWorkspace.outputs.name
  customerId: logAnalyticsWorkspace.outputs.customerId
}

output applicationInsightsInfo object = {
  id: applicationInsights.outputs.id
  name: applicationInsights.outputs.name
}

output aiServicesInfo object = {
  id: aiServices.outputs.id
  name: aiServices.outputs.name
  endpoint: aiServices.outputs.endpoint
  host: aiServices.outputs.host
  openAIEndpoint: aiServices.outputs.openAIEndpoint
  openAIHost: aiServices.outputs.openAIHost
}

output aiHubInfo object = {
  id: aiHub.outputs.id
  name: aiHub.outputs.name
  aiServicesConnectionName: aiHub.outputs.aiServicesConnectionName
  openAIServicesConnectionName: aiHub.outputs.openAIServicesConnectionName
}

output aiHubProjectInfo object = {
  id: aiHubProject.outputs.id
  name: aiHubProject.outputs.name
}

output aiModelsInfo object = {
  aiServiceModels: aiServiceModelDeployments
}
