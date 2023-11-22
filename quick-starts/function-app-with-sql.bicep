targetScope = 'subscription'

type appSettingInfo = {
  name: string
  value: string
}

type appSettingsInfo = {
  values: appSettingInfo[]
  functionApp: string[]
}

@minLength(1)
@maxLength(64)
@description('Name of the workload which is used to generate a short unique hash used in all resources.')
param workloadName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Name of the resource group. If empty, a unique name will be generated.')
param resourceGroupName string = ''

@description('Tags for all resources.')
param tags object = {}

@description('Name of the Managed Identity. If empty, a unique name will be generated.')
param managedIdentityName string = ''
@description('Name of the Key Vault. If empty, a unique name will be generated.')
param keyVaultName string = ''
@description('Name of the Log Analytics Workspace. If empty, a unique name will be generated.')
param logAnalyticsWorkspaceName string = ''
@description('Name of the Application Insights. If empty, a unique name will be generated.')
param applicationInsightsName string = ''
@description('Name of the Storage Account. If empty, a unique name will be generated.')
param storageAccountName string = ''
@description('Name of the SQL Server. If empty, a unique name will be generated.')
param sqlServerName string = ''
@description('Name of the SQL Server admin username. Defaults to sqladmin.')
param sqlServerAdminUsername string = 'sqladmin'
@description('Name of the SQL Server admin password.')
@secure()
param sqlServerAdminPassword string
@description('Name of the SQL Database. If empty, a unique name will be generated.')
param sqlDatabaseName string = ''
@description('Name of the App Service Plan. If empty, a unique name will be generated.')
param appServicePlanName string = ''
@description('Name of the Function App. If empty, a unique name will be generated.')
param functionAppName string = ''

@description('App Settings to be stored in the Key Vault and applied to the Function App.')
param appSettings appSettingsInfo = {
  values: []
  functionApp: []
}

var abbrs = loadJsonContent('../abbreviations.json')
var roles = loadJsonContent('../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}${workloadName}'
  location: location
  tags: union(tags, {})
}

module managedIdentity '../security/managed-identity.bicep' = {
  name: !empty(managedIdentityName) ? managedIdentityName : '${abbrs.managedIdentity}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(managedIdentityName) ? managedIdentityName : '${abbrs.managedIdentity}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

resource keyVaultSecretsOfficer 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.keyVaultSecretsOfficer
}

module keyVault '../security/key-vault.bicep' = {
  name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVault}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVault}${resourceToken}'
    location: location
    tags: union(tags, {})
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: keyVaultSecretsOfficer.id
      }
    ]
  }
}

module appSettingSecret '../security/key-vault-secret.bicep' = [for setting in appSettings.values: {
  name: '${setting.name}-secret'
  scope: resourceGroup
  params: {
    name: setting.name
    keyVaultName: keyVaultName
    value: setting.value
  }
  dependsOn: [
    keyVault
  ]
}]

module logAnalyticsWorkspace '../management_governance/log-analytics-workspace.bicep' = {
  name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.logAnalyticsWorkspace}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.logAnalyticsWorkspace}${resourceToken}'
    location: location
    tags: union(tags, {})
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.applicationInsights}${resourceToken}'
  }
}

module storageAccount '../storage/storage-account.bicep' = {
  name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageAccount}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageAccount}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard_LRS'
    }
  }
}

module sqlServer '../databases/sql-server.bicep' = {
  name: !empty(sqlServerName) ? sqlServerName : '${abbrs.sqlDatabaseServer}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(sqlServerName) ? sqlServerName : '${abbrs.sqlDatabaseServer}${resourceToken}'
    location: location
    tags: union(tags, {})
    adminUsername: sqlServerAdminUsername
    adminPassword: sqlServerAdminPassword
  }
}

module sqlDatabase '../databases/sql-database.bicep' = {
  name: !empty(sqlDatabaseName) ? sqlDatabaseName : '${abbrs.sqlDatabase}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(sqlDatabaseName) ? sqlDatabaseName : '${abbrs.sqlDatabase}${resourceToken}'
    location: location
    tags: union(tags, {})
    sqlServerName: sqlServer.name
  }
  dependsOn: [
    sqlServer
  ]
}

module appServicePlan '../compute/app-service-plan.bicep' = {
  name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.appServicePlan}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.appServicePlan}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Y1'
    }
    kind: 'functionapp'
  }
}

module functionAppSettings '../security/key-vault-secret-environment-variables.bicep' = {
  name: '${!empty(functionAppName) ? functionAppName : '${abbrs.functionApp}${resourceToken}'}-settings'
  scope: resourceGroup
  params: {
    keyVaultSecretUri: keyVault.outputs.uri
    variableNames: appSettings.functionApp
  }
  dependsOn: [
    keyVault
  ]
}

module functionApp '../compute/function-app.bicep' = {
  name: !empty(functionAppName) ? functionAppName : '${abbrs.functionApp}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(functionAppName) ? functionAppName : '${abbrs.functionApp}${resourceToken}'
    location: location
    tags: union(tags, {})
    functionAppIdentityId: managedIdentity.outputs.id
    appServicePlanId: appServicePlan.outputs.id
    appSettings: concat([
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: logAnalyticsWorkspace.outputs.instrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: logAnalyticsWorkspace.outputs.connectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.outputs.connectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'SqlServerConnectionString'
          value: '${sqlDatabase.outputs.connectionString};User ID=${sqlServerAdminUsername};Password=${sqlServerAdminPassword};'
        }
        {
          name: 'StorageAccountConnectionString'
          value: storageAccount.outputs.connectionString
        }
      ], functionAppSettings.outputs.environmentVariables)
  }
  dependsOn: [
    logAnalyticsWorkspace
    appServicePlan
    storageAccount
    keyVault
  ]
}
