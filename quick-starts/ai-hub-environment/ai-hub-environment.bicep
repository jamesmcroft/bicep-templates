import { modelDeploymentInfo, raiPolicyInfo } from '../../ai_ml/ai-services.bicep'
import { serverlessModelInfo } from '../../ai_ml/ai-hub-model-serverless-endpoint.bicep'

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

@description('Serverless model deployments for the AI Hub project.')
param serverlessModelDeployments serverlessModelInfo[] = [
  {
    name: 'Phi-3-mini-128k-instruct'
  }
]

var abbrs = loadJsonContent('../../abbreviations.json')
var roles = loadJsonContent('../../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource contributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.general.contributor
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.managementGovernance.resourceGroup}${workloadName}'
  location: location
  tags: union(tags, {})
}

module managedIdentity '../../security/managed-identity.bicep' = {
  name: '${abbrs.security.managedIdentity}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.security.managedIdentity}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

module resourceGroupRoleAssignment '../../security/resource-group-role-assignment.bicep' = {
  name: '${resourceGroup.name}-role-assignment'
  scope: resourceGroup
  params: {
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: contributor.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Storage account roles required for using Prompt Flow in AI Hubs
resource storageAccountContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageAccountContributor
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageBlobDataContributor
}

resource storageFileDataPrivilegedContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageFileDataPrivilegedContributor
}

resource storageTableDataContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageTableDataContributor
}

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
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageAccountContributor.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageBlobDataContributor.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageFileDataPrivilegedContributor.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageTableDataContributor.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

resource keyVaultAdministrator 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.security.keyVaultAdministrator
}

module keyVault '../../security/key-vault.bicep' = {
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
        principalType: 'ServicePrincipal'
      }
    ]
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

resource acrPush 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.containers.acrPush
}

resource acrPull 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.containers.acrPull
}

module containerRegistry '../../containers/container-registry.bicep' = {
  name: '${abbrs.containers.containerRegistry}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.containers.containerRegistry}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Basic'
    }
    adminUserEnabled: true
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: acrPush.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: acrPull.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

resource cognitiveServicesContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesContributor
}

resource cognitiveServicesOpenAIContributor 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesOpenAIContributor
}

resource cognitiveServicesOpenAIUser 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesOpenAIUser
}

module aiServices '../../ai_ml/ai-services.bicep' = {
  name: '${abbrs.ai.aiServices}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.aiServices}${resourceToken}'
    location: location
    tags: union(tags, {})
    identityId: managedIdentity.outputs.id
    raiPolicies: raiPolicies
    deployments: aiServiceModelDeployments
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: cognitiveServicesContributor.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: cognitiveServicesOpenAIContributor.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: cognitiveServicesOpenAIUser.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

resource azureMLDataScientist 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.azureMLDataScientist
}

module aiHub '../../ai_ml/ai-hub.bicep' = {
  name: '${abbrs.ai.aiHub}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.aiHub}${resourceToken}'
    friendlyName: 'Quickstart - AI Hub'
    descriptionInfo: 'Generated by the AI Hub Environment Quickstart'
    location: location
    tags: union(tags, {})
    identityId: managedIdentity.outputs.id
    storageAccountId: storageAccount.outputs.id
    keyVaultId: keyVault.outputs.id
    applicationInsightsId: applicationInsights.outputs.id
    containerRegistryId: containerRegistry.outputs.id
    aiServicesName: aiServices.outputs.name
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: azureMLDataScientist.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module aiHubProject '../../ai_ml/ai-hub-project.bicep' = {
  name: '${abbrs.ai.aiHubProject}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.ai.aiHubProject}${resourceToken}'
    friendlyName: 'Quickstart - AI Hub Project'
    descriptionInfo: 'Generated by the AI Hub Environment Quickstart'
    location: location
    tags: union(tags, {})
    identityId: managedIdentity.outputs.id
    aiHubName: aiHub.outputs.name
    serverlessModels: [
      for serverlessModelDeployment in serverlessModelDeployments: {
        name: '${serverlessModelDeployment.name}-${resourceToken}'
        model: serverlessModelDeployment
        keyVaultConfig: {
          name: keyVault.outputs.name
          primaryKeySecretName: '${serverlessModelDeployment.name}-${resourceToken}-Primary'
          secondaryKeySecretName: '${serverlessModelDeployment.name}-${resourceToken}-Secondary'
        }
      }
    ]
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: azureMLDataScientist.id
        principalType: 'ServicePrincipal'
      }
    ]
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

output storageAccountInfo object = {
  id: storageAccount.outputs.id
  name: storageAccount.outputs.name
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

output containerRegistryInfo object = {
  id: containerRegistry.outputs.id
  name: containerRegistry.outputs.name
  loginServer: containerRegistry.outputs.loginServer
}

output aiServicesInfo object = {
  id: aiServices.outputs.id
  name: aiServices.outputs.name
  endpoint: aiServices.outputs.endpoint
  host: aiServices.outputs.host
}

output aiHubInfo object = {
  id: aiHub.outputs.id
  name: aiHub.outputs.name
}

output aiHubProjectInfo object = {
  id: aiHubProject.outputs.id
  name: aiHubProject.outputs.name
  serverlessModelDeployments: aiHubProject.outputs.serverlessModelDeployments
}
