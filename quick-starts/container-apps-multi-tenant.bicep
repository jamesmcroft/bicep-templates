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

@description('Name of the SQL Server admin username. Defaults to sqladmin.')
param sqlServerAdminUsername string = 'sqladmin'
@description('Name of the SQL Server admin password.')
@secure()
param sqlServerAdminPassword string

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

resource acrPull 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.containers.acrPull
}

module containerRegistry '../containers/container-registry.bicep' = {
  name: '${abbrs.containers.containerRegistry}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.containers.containerRegistry}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Basic'
    }
    adminUserEnabled: true
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: acrPull.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

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

resource azureServiceBusDataOwner 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.integration.azureServiceBusDataOwner
}

module serviceBusNamespace '../integration/service-bus-namespace.bicep' = {
  name: '${abbrs.integration.serviceBusNamespace}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.integration.serviceBusNamespace}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard'
    }
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionId: azureServiceBusDataOwner.id
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

module sqlElasticPool '../databases/sql-elastic-pool.bicep' = {
  name: '${abbrs.databases.sqlElasticPool}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.databases.sqlElasticPool}${resourceToken}'
    location: location
    tags: union(tags, {})
    sku: {
      name: 'BasicPool'
    }
    sqlServerName: sqlServer.outputs.name
  }
}

module containerAppsEnvironment '../containers/container-apps-environment.bicep' = {
  name: '${abbrs.containers.containerAppsEnvironment}${resourceToken}'
  scope: resourceGroup
  params: {
    name: '${abbrs.containers.containerAppsEnvironment}${resourceToken}'
    location: location
    tags: union(tags, {})
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

module daprPubSubServiceBus '../containers/container-apps-environment-dapr-pubsub-service-bus.bicep' = {
  name: 'dapr-pubsub-servicebus'
  scope: resourceGroup
  params: {
    name: 'dapr-pubsub-servicebus'
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    serviceBusNamespaceName: serviceBusNamespace.outputs.name
    identityClientId: managedIdentity.outputs.clientId
    scopes: []
  }
}

module daprSecretStoreKeyVault '../containers/container-apps-environment-dapr-secretstores-key-vault.bicep' = {
  name: 'dapr-secretstore-keyvault'
  scope: resourceGroup
  params: {
    name: 'dapr-secretstore-keyvault'
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    keyVaultName: keyVault.outputs.name
    identityClientId: managedIdentity.outputs.clientId
    scopes: []
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

output containerRegistryInfo object = {
  id: containerRegistry.outputs.id
  name: containerRegistry.outputs.name
  loginServer: containerRegistry.outputs.loginServer
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

output serviceBusNamespaceInfo object = {
  id: serviceBusNamespace.outputs.id
  name: serviceBusNamespace.outputs.name
}

output sqlServerInfo object = {
  id: sqlServer.outputs.id
  name: sqlServer.outputs.name
  elasticPoolName: sqlElasticPool.outputs.name
}

output containerAppsEnvironmentInfo object = {
  id: containerAppsEnvironment.outputs.id
  name: containerAppsEnvironment.outputs.name
  defaultDomain: containerAppsEnvironment.outputs.defaultDomain
  staticIp: containerAppsEnvironment.outputs.staticIp
  daprPubSubName: daprPubSubServiceBus.outputs.name
  daprSecretStoreName: daprSecretStoreKeyVault.outputs.name
}
