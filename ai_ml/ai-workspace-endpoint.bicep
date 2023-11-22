@export()
type endpointInfo = {
  name: 'Azure.OpenAI' | 'Azure.ContentSafety' | 'Azure.Speech'
  endpointResourceId: string
}

@description('Name of the AI/ML workspace associated with the connection.')
param workspaceName string
@description('Connection information.')
param endpoint endpointInfo

resource workspace 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' existing = {
  name: workspaceName
}

resource workspaceEndpoint 'Microsoft.MachineLearningServices/workspaces/endpoints@2023-08-01-preview' = {
  name: endpoint.name
  parent: workspace
  properties: {
    name: endpoint.name
    endpointType: endpoint.name
    associatedResourceId: endpoint.endpointResourceId
  }
}

// @description('The deployed ML workspace connection resource.')
// output resource resource = workspace::workspaceEndpoint
// @description('ID for the deployed ML workspace connection resource.')
// output id string = workspace::workspaceEndpoint.id
// @description('Name for the deployed ML workspace connection resource.')
// output name string = workspace::workspaceEndpoint.name
