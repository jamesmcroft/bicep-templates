import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string

@description('Name for the Event Hub Namespace associated with the Event Hub.')
param eventHubNamespaceName string
@description('Number of days to retain events in the Event Hub. Default is 1 day.')
param retentionInDays int = 1
@description('Number of partitions in the Event Hub. Default is 1 partition.')
param partitionCount int = 1
@description('Role assignments to create for the Event Hub resource.')
param roleAssignments roleAssignmentInfo[] = []

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' existing = {
  name: eventHubNamespaceName
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  name: name
  parent: eventHubNamespace
  properties: {
    messageRetentionInDays: retentionInDays
    partitionCount: partitionCount
  }

  resource listenSendAuthorization 'authorizationRules' = {
    name: 'ListenSend'
    properties: {
      rights: [
        'Listen'
        'Send'
      ]
    }
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(eventHub.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: eventHub
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

@description('The deployed Event Hub resource.')
output resource resource = eventHub
@description('ID for the deployed Event Hub resource.')
output id string = eventHub.id
@description('Name for the deployed Event Hub resource.')
output name string = eventHub.name
