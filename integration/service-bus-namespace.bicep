@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type roleAssignmentInfo = {
    roleDefinitionId: string
    principalId: string
}

type skuInfo = {
    name: 'Basic' | 'Premium' | 'Standard'
}

type serviceBusConfigInfo = {
    disableLocalAuth: bool
    zoneRedundant: bool
}

@description('Service Bus Namespace SKU. Defaults to Basic.')
param sku skuInfo = {
    name: 'Basic'
}
@description('Service Bus Namespace configuration.')
param serviceBusConfig serviceBusConfigInfo = {
    disableLocalAuth: false
    zoneRedundant: false
}
@description('Role assignments to create for the Service Bus Namespace.')
param roleAssignments roleAssignmentInfo[] = []

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
    name: name
    location: location
    tags: tags
    sku: sku
    properties: {
        disableLocalAuth: serviceBusConfig.disableLocalAuth
        zoneRedundant: serviceBusConfig.zoneRedundant
    }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
    name: guid(serviceBusNamespace.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: serviceBusNamespace
    properties: {
        principalId: roleAssignment.principalId
        roleDefinitionId: roleAssignment.roleDefinitionId
        principalType: 'ServicePrincipal'
    }
}]

var primaryConnectionString = listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', '2021-11-01').primaryConnectionString

@description('The deployed Service Bus Namespace resource.')
output resource resource = serviceBusNamespace
@description('ID for the deployed Service Bus Namespace resource.')
output id string = serviceBusNamespace.id
@description('Name for the deployed Service Bus Namespace resource.')
output name string = serviceBusNamespace.name
@description('Connection string of the Service Bus namespace resource.')
output connectionString string = primaryConnectionString
