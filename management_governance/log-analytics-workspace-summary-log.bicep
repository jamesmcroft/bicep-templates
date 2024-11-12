@description('Name of the resource.')
param name string
@description('Name for the Log Analytics Workspace resource associated with the summary logs.')
param logAnalyticsWorkspaceName string
@description('Description of the summary logs.')
param summaryDescription string
@description('Kusto query for the summary logs.')
param query string
@description('The execution interval in minutes, and the lookback time range.')
@allowed([
  20
  30
  60
  120
  180
  360
  720
  1440
])
param binSize int = 60
@description('Destination table for the summary logs. Name must end with "_CL".')
param destinationTable string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource summaryLog 'Microsoft.OperationalInsights/workspaces/summaryLogs@2023-01-01-preview' = {
  name: '${logAnalyticsWorkspace.name}/${name}'
  properties: {
    ruleType: 'User'
    description: summaryDescription
    ruleDefinition: {
      query: query
      binSize: binSize
      destinationTable: destinationTable
    }
  }
}
