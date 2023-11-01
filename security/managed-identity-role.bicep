@description('The principal ID for the identity.')
param identityPrincipalId string
@description('The ID of the resource associated with the role.')
param resourceId string
@description('The ID of the role definition.')
param roleDefinitionId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: resourceGroup()
    name: roleDefinitionId
}

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(resourceId, identityPrincipalId, roleDefinition.id)
    properties: {
        principalId: identityPrincipalId
        roleDefinitionId: roleDefinition.id
        principalType: 'ServicePrincipal'
    }
}
