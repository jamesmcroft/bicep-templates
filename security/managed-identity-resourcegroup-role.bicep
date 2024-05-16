import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Role assignment information.')
param roleAssignment roleAssignmentInfo
@description('The ID of the resource associated with the role.')
param resourceId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: roleAssignment.roleDefinitionId
}

resource resourceGroupRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceId, roleAssignment.principalId, roleDefinition.id)
  scope: resourceGroup()
  properties: {
    principalId: roleAssignment.principalId
    roleDefinitionId: roleAssignment.roleDefinitionId
    principalType: roleAssignment.principalType
  }
}
