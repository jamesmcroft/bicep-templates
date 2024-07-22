@export()
@description('Connection information for the AI/ML workspace.')
type connectionInfo = {
  @description('Name of the connection.')
  name: string
  @description('Category of the connection.')
  category: string
  @description('Target of the connection.')
  target: string
  @description('Authentication type for the connection target.')
  authType:
    | 'AAD'
    | 'AccessKey'
    | 'AccountKey'
    | 'ApiKey'
    | 'CustomKeys'
    | 'ManagedIdentity'
    | 'None'
    | 'OAuth2'
    | 'PAT'
    | 'SAS'
    | 'ServicePrincipal'
    | 'UsernamePassword'
  @description('Credentials for the connection target.')
  credentials: object?
}

@description('Name of the AI/ML workspace associated with the connection.')
param workspaceName string
@description('Connection information.')
param connection connectionInfo

resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' existing = {
  name: workspaceName

  resource workspaceConnection 'connections@2024-01-01-preview' = {
    name: connection.name
    properties: {
      category: connection.category
      target: connection.target
      authType: connection.authType
      credentials: connection.credentials
    }
  }
}

@description('The deployed ML workspace connection resource.')
output resource resource = workspace::workspaceConnection
@description('ID for the deployed ML workspace connection resource.')
output id string = workspace::workspaceConnection.id
@description('Name for the deployed ML workspace connection resource.')
output name string = workspace::workspaceConnection.name
