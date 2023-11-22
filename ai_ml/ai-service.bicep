@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type roleAssignmentInfo = {
  roleDefinitionId: string
  principalId: string
}

type keyVaultSecretInfo = {
  name: string
  property: 'PrimaryKey'
}

type keyVaultSecretsInfo = {
  name: string
  secrets: keyVaultSecretInfo[]
}

@description('List of deployments for the AI service.')
param deployments array = []
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Properties to store in a Key Vault.')
param keyVaultSecrets keyVaultSecretsInfo = {
  name: ''
  secrets: []
}
@description('Role assignments to create for the Cognitive Service instance.')
param roleAssignments roleAssignmentInfo[] = []

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: publicNetworkAccess
  }
  sku: {
    name: 'S0'
  }
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for deployment in deployments: {
  parent: aiServices
  name: deployment.name
  properties: {
    model: contains(deployment, 'model') ? deployment.model : null
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: contains(deployment, 'sku') ? deployment.sku : {
    name: 'Standard'
    capacity: 20
  }
}]

module keyVaultSecret '../security/key-vault-secret.bicep' = [for secret in keyVaultSecrets.secrets: {
  name: '${secret.name}-secret'
  params: {
    keyVaultName: keyVaultSecrets.?name!
    name: secret.name
    value: secret.property == 'PrimaryKey' ? aiServices.listKeys().key1 : ''
  }
}]

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
  name: guid(aiServices.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
  scope: aiServices
  properties: {
    principalId: roleAssignment.principalId
    roleDefinitionId: roleAssignment.roleDefinitionId
    principalType: 'ServicePrincipal'
  }
}]

@description('ID for the deployed AI Service resource.')
output id string = aiServices.id
@description('Name for the deployed AI Service resource.')
output name string = aiServices.name
@description('Endpoint for the deployed AI Service resource.')
output endpoint string = aiServices.properties.endpoint
@description('Host for the deployed AI Service resource.')
output host string = split(aiServices.properties.endpoint, '/')[2]
