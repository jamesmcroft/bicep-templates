@description('Name of the resource.')
param name string
@description('Name for the Application Insights resource.')
param applicationInsightsName string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
    name: 'CapacityReservation' | 'Free' | 'LACluster' | 'PerGB2018' | 'PerNode' | 'Premium' | 'Standalone' | 'Standard'
}

@description('Log Analytics Workspace SKU. Defaults to PerGB2018.')
param sku skuInfo = {
    name: 'PerGB2018'
}
@description('Retention period (in days) for the Log Analytics Workspace. Defaults to 30.')
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
    name: name
    location: location
    tags: tags
    properties: {
        retentionInDays: retentionInDays
        features: {
            searchVersion: 1
        }
        sku: sku
    }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
    name: applicationInsightsName
    location: location
    tags: tags
    kind: 'web'
    properties: {
        Application_Type: 'web'
        WorkspaceResourceId: logAnalyticsWorkspace.id
    }
}

var primarySharedKey = listKeys(logAnalyticsWorkspace.id, '2022-10-01').primarySharedKey

@description('The deployed Log Analytics Workspace resource.')
output resource resource = logAnalyticsWorkspace
@description('ID for the deployed Log Analytics Workspace resource.')
output id string = logAnalyticsWorkspace.id
@description('Name for the deployed Log Analytics Workspace resource.')
output name string = logAnalyticsWorkspace.name
@description('The deployed Application Insights resource.')
output applicationInsightsResource resource = applicationInsights
@description('ID for the deployed Application Insights resource.')
output applicationInsightsId string = applicationInsights.id
@description('Name for the deployed Application Insights resource.')
output applicationInsightsName string = applicationInsights.name
@description('Customer ID for the deployed Log Analytics Workspace resource.')
output customerId string = logAnalyticsWorkspace.properties.customerId
@description('Shared key for the deployed Log Analytics Workspace resource.')
output sharedKey string = primarySharedKey
@description('Instrumentation Key for the deployed Application Insights resource.')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
@description('Connection string for the deployed Application Insights resource.')
output connectionString string = applicationInsights.properties.ConnectionString
