import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('Information about a model deployment for AI Services.')
type modelDeploymentInfo = {
  @description('Name for the model deployment. Must be unique within AI Services.')
  name: string
  @description('Information about the model to deploy.')
  model: {
    @description('Format of the model. Expects "OpenAI".')
    format: string
    @description('ID of the model, e.g., gpt-35-turbo. For more information on model IDs: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models')
    name: string
    @description('Version of the model, e.g., 0125. For more information on model versions: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models')
    version: string
  }?
  @description('Name of the content filter policy to apply to the model deployment.')
  raiPolicyName: string?
  @description('Sizing for the model deployment.')
  sku: {
    @description('Name of the SKU. Expects "Standard".')
    name: string
    @description('TPM quota allocation for the model deployment. For more information on model quota limits per region: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models')
    capacity: int
  }?
}

@description('List of model deployments.')
param deployments modelDeploymentInfo[] = []
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Whether to disable local (key-based) authentication. Defaults to true.')
param disableLocalAuth bool = true
@description('Role assignments to create for the AI Services instance.')
param roleAssignments roleAssignmentInfo[] = []

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  properties: {
    customSubDomainName: toLower(name)
    disableLocalAuth: disableLocalAuth
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
  }
  sku: {
    name: 'S0'
  }
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [
  for deployment in deployments: {
    parent: aiServices
    name: deployment.name
    properties: {
      model: deployment.?model ?? null
      raiPolicyName: deployment.?raiPolicyName ?? null
    }
    sku: deployment.?sku ?? {
      name: 'Standard'
      capacity: 20
    }
  }
]

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(aiServices.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: aiServices
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

@description('The deployed AI Services resource.')
output resource resource = aiServices
@description('ID for the deployed AI Services resource.')
output id string = aiServices.id
@description('Name for the deployed AI Services resource.')
output name string = aiServices.name
@description('Endpoint for the deployed AI Services resource.')
output endpoint string = aiServices.properties.endpoint
@description('Host for the deployed AI Services resource.')
output host string = split(aiServices.properties.endpoint, '/')[2]
