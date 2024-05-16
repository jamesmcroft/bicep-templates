targetScope = 'subscription'

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

@description('Information about an app setting to store in Key Vault.')
type appSettingInfo = {
  @description('Name of the app setting.')
  name: string
  @description('Value of the app setting.')
  value: string
}

@description('Information about the app settings for the function app to store in Key Vault.')
type appSettingsInfo = {
  @description('App settings for the function app.')
  values: appSettingInfo[]
  @description('Names of all the variables in the Key Vault to assign to the function app.')
  functionApp: string[]
}

@description('Name of the SQL Server admin username. Defaults to sqladmin.')
param sqlServerAdminUsername string = 'sqladmin'
@description('Name of the SQL Server admin password.')
@secure()
param sqlServerAdminPassword string
@description('App Settings to be stored in the Key Vault and applied to the Function App.')
param appSettings appSettingsInfo = {
  values: []
  functionApp: []
}

var abbrs = loadJsonContent('../abbreviations.json')
var roles = loadJsonContent('../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.managementGovernance.resourceGroup}${workloadName}'
  location: location
  tags: union(tags, {})
}

module managedIdentity '../security/managed-identity.bicep' = {
  name: '${abbrs.security.managedIdentity}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.security.managedIdentity}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

resource keyVaultSecretsOfficer 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.security.keyVaultSecretsOfficer
}

module keyVault '../security/key-vault.bicep' = {
  name: '${abbrs.security.keyVault}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.security.keyVault}${resourceToken}'
    location: location
    tags: union(tags, {})
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: keyVaultSecretsOfficer.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module appSettingSecret '../security/key-vault-secret.bicep' = [
  for setting in appSettings.values: {
    name: '${setting.name}-secret'
    scope: resourceGroup
    params: {
      name: setting.name
      keyVaultName: keyVault.outputs.name
      value: setting.value
    }
  }
]

module logAnalyticsWorkspace '../management_governance/log-analytics-workspace.bicep' = {
  name: '${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

module applicationInsights '../management_governance/application-insights.bicep' = {
  name: '${abbrs.managementGovernance.applicationInsights}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.managementGovernance.applicationInsights}${resourceToken}'
    location: location
    tags: union(tags, {})
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

// Required RBAC roles for Azure Functions to access the storage account
// https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob&pivots=programming-language-csharp#connecting-to-host-storage-with-an-identity

resource storageAccountContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.storage.storageAccountContributor
}

resource storageBlobDataOwner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.storage.storageBlobDataOwner
}

resource storageQueueDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.storage.storageQueueDataContributor
}

resource storageTableDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.storage.storageTableDataContributor
}

module storageAccount '../storage/storage-account.bicep' = {
  name: '${abbrs.storage.storageAccount}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.storage.storageAccount}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard_LRS'
    }
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageAccountContributor.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageBlobDataOwner.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageQueueDataContributor.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: storageTableDataContributor.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module sqlServer '../databases/sql-server.bicep' = {
  name: '${abbrs.databases.sqlDatabaseServer}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.databases.sqlDatabaseServer}${resourceToken}'
    location: location
    tags: union(tags, {})
    adminUsername: sqlServerAdminUsername
    adminPassword: sqlServerAdminPassword
  }
}

module sqlDatabase '../databases/sql-database.bicep' = {
  name: '${abbrs.databases.sqlDatabase}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.databases.sqlDatabase}${resourceToken}'
    location: location
    tags: union(tags, {})
    sqlServerName: sqlServer.outputs.name
  }
}

module appServicePlan '../compute/app-service-plan.bicep' = {
  name: '${abbrs.compute.appServicePlan}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.compute.appServicePlan}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}

module functionAppSettings '../security/key-vault-secret-environment-variables.bicep' = {
  name: '${abbrs.compute.functionApp}${resourceToken}-settings'
  scope: resourceGroup
  params: {
    keyVaultSecretUri: keyVault.outputs.uri
    variableNames: appSettings.functionApp
  }
}

module functionApp '../compute/function-app.bicep' = {
  name: '${abbrs.compute.functionApp}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.compute.functionApp}${resourceToken}'
    location: location
    tags: union(tags, {})
    identityId: managedIdentity.outputs.id
    appServicePlanId: appServicePlan.outputs.id
    appSettings: concat(
      [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.outputs.connectionString
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.outputs.name
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: managedIdentity.outputs.clientId
        }
        {
          name: 'ManagedIdentityClientId'
          value: managedIdentity.outputs.clientId
        }
        {
          name: 'SqlServerConnectionString'
          value: '${sqlDatabase.outputs.connectionString};User ID=${sqlServerAdminUsername};Password=${sqlServerAdminPassword};'
        }
        {
          name: 'StorageAccountName'
          value: storageAccount.outputs.name
        }
      ],
      functionAppSettings.outputs.environmentVariables
    )
  }
}

output subscriptionInfo object = {
  id: subscription().subscriptionId
  tenantId: subscription().tenantId
}

output resourceGroupInfo object = {
  id: resourceGroup.id
  name: resourceGroup.name
  location: resourceGroup.location
  workloadName: workloadName
}

output managedIdentityInfo object = {
  id: managedIdentity.outputs.id
  name: managedIdentity.outputs.name
  principalId: managedIdentity.outputs.principalId
  clientId: managedIdentity.outputs.clientId
}

output keyVaultInfo object = {
  id: keyVault.outputs.id
  name: keyVault.outputs.name
  uri: keyVault.outputs.uri
}

output logAnalyticsWorkspaceInfo object = {
  id: logAnalyticsWorkspace.outputs.id
  name: logAnalyticsWorkspace.outputs.name
  customerId: logAnalyticsWorkspace.outputs.customerId
}

output applicationInsightsInfo object = {
  id: applicationInsights.outputs.id
  name: applicationInsights.outputs.name
}

output storageAccountInfo object = {
  id: storageAccount.outputs.id
  name: storageAccount.outputs.name
}

output sqlServerInfo object = {
  id: sqlServer.outputs.id
  name: sqlServer.outputs.name
  databaseName: sqlDatabase.outputs.name
}

output appServicePlanInfo object = {
  id: appServicePlan.outputs.id
  name: appServicePlan.outputs.name
}

output functionAppInfo object = {
  id: functionApp.outputs.id
  name: functionApp.outputs.name
  host: functionApp.outputs.host
}
