@description('Principal ID for the identity.')
param identityPrincipalId string
@description('The ID of the resource associated with the role.')
param resourceId string
@description('Role definition associated with the role assignment.')
param roleDefinition resource 'Microsoft.Authorization/roleDefinitions@2022-04-01'

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(resourceId, identityPrincipalId, roleDefinition.id)
    scope: resourceGroup()
    properties: {
        principalId: identityPrincipalId
        roleDefinitionId: roleDefinition.id
        principalType: 'ServicePrincipal'
    }
}
