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

type keyVaultSecretsInfo = {
  keyVaultName: string
  primaryKeySecretName: string
}

@description('Cognitive Services SKU. Defaults to S0.')
param sku object = {
  name: 'S0'
}
@description('Cognitive Services Kind. Defaults to OpenAI.')
@allowed([
  'Bing.Speech'
  'SpeechTranslation'
  'TextTranslation'
  'Bing.Search.v7'
  'Bing.Autosuggest.v7'
  'Bing.CustomSearch'
  'Bing.SpellCheck.v7'
  'Bing.EntitySearch'
  'Face'
  'ComputerVision'
  'ContentModerator'
  'TextAnalytics'
  'LUIS'
  'SpeakerRecognition'
  'CustomSpeech'
  'CustomVision.Training'
  'CustomVision.Prediction'
  'OpenAI'
])
param kind string = 'OpenAI'
@description('List of deployments for Cognitive Services.')
param deployments array = []
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Properties to store in a Key Vault.')
param keyVaultConfig keyVaultSecretsInfo = {
  keyVaultName: ''
  primaryKeySecretName: ''
}
@description('Role assignments to create for the Cognitive Service instance.')
param roleAssignments roleAssignmentInfo[] = []

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: publicNetworkAccess
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for deployment in deployments: {
  parent: cognitiveServices
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

module primaryKeySecret '../security/key-vault-secret.bicep' = if (!empty(keyVaultConfig.primaryKeySecretName)) {
  name: '${keyVaultConfig.primaryKeySecretName}-secret'
  params: {
    keyVaultName: keyVaultConfig.keyVaultName
    name: keyVaultConfig.primaryKeySecretName
    value: cognitiveServices.listKeys().key1
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
  name: guid(cognitiveServices.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
  scope: cognitiveServices
  properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: 'ServicePrincipal'
  }
}]

@description('ID for the deployed Cognitive Services resource.')
output id string = cognitiveServices.id
@description('Name for the deployed Cognitive Services resource.')
output name string = cognitiveServices.name
@description('Endpoint for the deployed Cognitive Services resource.')
output endpoint string = cognitiveServices.properties.endpoint
@description('Host for the deployed Cognitive Services resource.')
output host string = split(cognitiveServices.properties.endpoint, '/')[2]
