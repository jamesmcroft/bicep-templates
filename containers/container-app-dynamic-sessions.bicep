import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('The number of seconds to wait before scaling down the pool after the last session is completed. Must be greater than or equal to 300 seconds. Defaults to 300 seconds.')
@minValue(300)
param cooldownPeriodInSeconds int = 300
@description('The maximum number of concurrent sessions that can be created in the pool. Defaults to 20.')
param maxConcurrentSessions int = 20
@description('The number of sessions to keep ready in the pool. Defaults to 1.')
param readySessionInstances int = 1
@description('Role assignments to create for the dynamic session pool.')
param roleAssignments roleAssignmentInfo[] = []

resource dynamicSession 'Microsoft.App/sessionPools@2024-10-02-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    containerType: 'PythonLTS'
    dynamicPoolConfiguration: {
      cooldownPeriodInSeconds: cooldownPeriodInSeconds
      executionType: 'Timed'
    }
    poolManagementType: 'Dynamic'
    scaleConfiguration: {
      maxConcurrentSessions: maxConcurrentSessions
      readySessionInstances: readySessionInstances
    }
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(dynamicSession.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: dynamicSession
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

@description('The deployed dynamic session pool resource.')
output resource resource = dynamicSession
@description('ID for the deployed dynamic session pool resource.')
output id string = dynamicSession.id
@description('Name for the deployed dynamic session pool resource.')
output name string = dynamicSession.name
@description('Pool management endpoint for the dynamic session pool.')
output endpoint string = dynamicSession.properties.poolManagementEndpoint
