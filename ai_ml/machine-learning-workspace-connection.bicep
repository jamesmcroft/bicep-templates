@export()
type connectionInfo = {
  name: string
  category: 'ADLSGen2' | 'ApiKey' | 'AzureMySqlDb' | 'AzureOpenAI' | 'AzurePostgresDb' | 'AzureSqlDb' | 'AzureSynapseAnalytics' | 'CognitiveSearch' | 'CognitiveService' | 'ContainerRegistry' | 'CustomKeys' | 'Git' | 'PythonFeed' | 'Redis' | 'S3' | 'Snowflake'
  target: string
  authType: 'AccessKey' | 'ApiKey' | 'CustomKeys' | 'ManagedIdentity' | 'None' | 'PAT' | 'SAS' | 'ServicePrincipal' | 'UsernamePassword'
  credentials: object?
}

@description('Name of the AI/ML workspace associated with the connection.')
param workspaceName string
@description('Connection information.')
param connection connectionInfo

resource workspace 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' existing = {
  name: workspaceName

  resource workspaceConnection 'connections' = {
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
