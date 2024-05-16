import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('Document Intelligence SKU. Defaults to S0.')
param sku object = {
  name: 'S0'
}
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Whether to disable local (key-based) authentication. Defaults to true.')
param disableLocalAuth bool = true
@description('Role assignments to create for the Document Intelligence instance.')
param roleAssignments roleAssignmentInfo[] = []

resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'FormRecognizer'
  identity: {
    type: 'SystemAssigned'
  }
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
  sku: sku
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(documentIntelligence.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: documentIntelligence
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

@description('The deployed Document Intelligence resource.')
output resource resource = documentIntelligence
@description('ID for the deployed Document Intelligence resource.')
output id string = documentIntelligence.id
@description('Name for the deployed Document Intelligence resource.')
output name string = documentIntelligence.name
@description('Endpoint for the deployed Document Intelligence resource.')
output endpoint string = documentIntelligence.properties.endpoint
@description('Host for the deployed Document Intelligence resource.')
output host string = split(documentIntelligence.properties.endpoint, '/')[2]
@description('Identity principal ID for the deployed Document Intelligence resource.')
output systemIdentityPrincipalId string = documentIntelligence.identity.principalId
