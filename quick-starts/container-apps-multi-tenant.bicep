targetScope = 'subscription'

type appSettingInfo = {
  name: string
  value: string
}

type appSettingsInfo = {
  values: appSettingInfo[]
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
@description('Name of the Container Registry. If empty, a unique name will be generated.')
param containerRegistryName string = ''
@description('Name of the Log Analytics Workspace. If empty, a unique name will be generated.')
param logAnalyticsWorkspaceName string = ''
@description('Name of the Application Insights. If empty, a unique name will be generated.')
param applicationInsightsName string = ''
@description('Name of the Service Bus Namespace. If empty, a unique name will be generated.')
param serviceBusNamespaceName string = ''
@description('Name of the SQL Server. If empty, a unique name will be generated.')
param sqlServerName string = ''
@description('Name of the SQL Server admin username. Defaults to sqladmin.')
param sqlServerAdminUsername string = 'sqladmin'
@description('Name of the SQL Server admin password.')
@secure()
param sqlServerAdminPassword string
@description('Name of the SQL Elastic Pool. If empty, a unique name will be generated.')
param sqlElasticPoolName string = ''
@description('Name of the Key Vault. If empty, a unique name will be generated.')
param keyVaultName string = ''
@description('Name of the Container Apps Environment. If empty, a unique name will be generated.')
param containerAppsEnvironmentName string = ''

@description('App Settings to be stored in the Key Vault.')
param appSettings appSettingsInfo = {
  values: []
}

var abbrs = loadJsonContent('../abbreviations.json')
var roles = loadJsonContent('../roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}${workloadName}'
  location: location
  tags: tags
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

resource containerRegistryPull 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.acrPull
}

module containerRegistry '../containers/container-registry.bicep' = {
  name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistry}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistry}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Basic'
    }
    adminUserEnabled: true
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: containerRegistryPull.id
      }
    ]
  }
}

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

module applicationInsightsConnectionStringSecret '../security/key-vault-secret.bicep' = {
  name: 'ApplicationInsightsConnectionString-secret'
  scope: resourceGroup
  params: {
    name: 'ApplicationInsightsConnectionString'
    keyVaultName: keyVault.name
    value: logAnalyticsWorkspace.outputs.connectionString
  }
}

resource serviceBusDataOwner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.serviceBusDataOwner
}

module serviceBusNamespace '../integration/service-bus-namespace.bicep' = {
  name: !empty(serviceBusNamespaceName) ? serviceBusNamespaceName : '${abbrs.serviceBusNamespace}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(serviceBusNamespaceName) ? serviceBusNamespaceName : '${abbrs.serviceBusNamespace}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard'
    }
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: serviceBusDataOwner.id
      }
    ]
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

module sqlElasticPool '../databases/sql-elastic-pool.bicep' = {
  name: !empty(sqlElasticPoolName) ? sqlElasticPoolName : '${abbrs.sqlElasticPool}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(sqlElasticPoolName) ? sqlElasticPoolName : '${abbrs.sqlElasticPool}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'BasicPool'
    }
    sqlServerName: sqlServer.outputs.name
  }
}

module containerAppsEnvironment '../containers/container-apps-environment.bicep' = {
  name: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.containerAppsEnvironment}${resourceToken}'
  scope: resourceGroup
  params: {
    name: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.containerAppsEnvironment}${resourceToken}'
    location: location
    tags: union(tags, {})
    logAnalyticsConfig: {
      customerId: logAnalyticsWorkspace.outputs.customerId
      sharedKey: logAnalyticsWorkspace.outputs.sharedKey
    }
  }
}

// Add Container App module declarations here. Remember to update the Dapr component scopes to include the container image name if you want to add them to the Dapr sidecar.

module daprPubSubServiceBus '../containers/dapr-pubsub-service-bus.bicep' = {
  name: 'dapr-pubsub-servicebus'
  scope: resourceGroup
  params: {
    name: 'dapr-pubsub-servicebus'
    containerAppsEnvironmentName: containerAppsEnvironment.name
    serviceBusConnectionString: serviceBusNamespace.outputs.connectionString
    identityClientId: managedIdentity.outputs.clientId
    scopes: []
  }
}

module daprSecretStoreKeyVault '../containers/dapr-secretstore-key-vault.bicep' = {
  name: 'dapr-secretstore-keyvault'
  scope: resourceGroup
  params: {
    name: 'dapr-secretstore-keyvault'
    containerAppsEnvironmentName: containerAppsEnvironment.name
    keyVaultName: keyVaultName
    identityClientId: managedIdentity.outputs.clientId
    scopes: []
  }
}
