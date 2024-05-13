@description('Principal ID for the identity.')
param identityPrincipalId string
@description('The ID of the resource associated with the role.')
param resourceId string
@description('The ID of the role definition associated with the role assignment.')
param roleDefinitionId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roleDefinitionId
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceId, identityPrincipalId, roleDefinition.id)
  scope: resourceGroup()
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: roleDefinition.id
    principalType: 'ServicePrincipal'
  }
}
