@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type ingressConfigInfo = {
    external: bool
    targetPort: int
    transport: string?
    ipSecurityRestrictions: array?
}

type resourceConfigInfo = {
    cpu: string
    memory: string
}

type scaleConfigInfo = {
    minReplicas: int
    maxReplicas: int
    rules: array?
}

@description('ID for the Container Apps Environment associated with the Container App.')
param containerAppsEnvironmentId string
@description('ID for the Managed Identity associated with the Container App.')
param containerAppIdentityId string
@description('Name for the Container Registry associated with the Container App.')
param containerRegistryName string = ''
@description('Whether the container image exists in the Container Registry. Defaults to true.')
param imageInContainerRegistry bool = true
@description('Name for the container image associated with the Container App.')
param containerImageName string
@description('Ingress configuration for the container.')
param containerIngress ingressConfigInfo = {
    external: true
    targetPort: 80
    transport: 'auto'
    ipSecurityRestrictions: []
}
@description('Resource configuration for the container.')
param containerResources resourceConfigInfo = {
    cpu: '.25'
    memory: '.5Gi'
}
@description('Scale configuration for the container.')
param containerScale scaleConfigInfo = {
    minReplicas: 1
    maxReplicas: 3
    rules: []
}
@description('Environment variables for the container.')
param environmentVariables array = []
@description('Secrets for the container.')
param secrets array = []
@description('Volume definitions for the container.')
param volumes array = []
@description('Volume mounts for the container.')
param volumeMounts array = []
@description('Whether Dapr is enabled for the Container App. Defaults to true.')
param daprEnabled bool = true

var daprAppId = replace(containerImageName, '/', '-')

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
    name: name
    location: location
    tags: tags
    identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${containerAppIdentityId}': {}
        }
    }
    properties: {
        environmentId: containerAppsEnvironmentId
        configuration: {
            secrets: secrets
            registries: imageInContainerRegistry ? [
                {
                    server: '${containerRegistryName}.azurecr.io'
                    identity: containerAppIdentityId
                }
            ] : []
            dapr: daprEnabled ? {
                enabled: true
                appId: daprAppId
                appPort: containerIngress.targetPort
            } : {
                enabled: false
            }
            ingress: containerIngress
        }
        template: {
            containers: [
                {
                    image: imageInContainerRegistry ? '${containerRegistryName}.azurecr.io/${containerImageName}:latest' : containerImageName
                    name: name
                    resources: containerResources
                    env: environmentVariables
                    volumeMounts: volumeMounts
                }
            ]
            scale: containerScale
            volumes: volumes
        }
    }
}

@description('ID for the deployed Container App resource.')
output id string = containerApp.id
@description('Name for the deployed Container App resource.')
output name string = containerApp.name
@description('Latest FQDN for the deployed Container App resource.')
output fqdn string = containerApp.properties.latestRevisionFqdn
@description('Latest URL for the deployed Container App resource.')
output url string = 'https://${containerApp.properties.latestRevisionFqdn}'
@description('Dapr ID for the deployed Container App resource.')
output daprId string = daprAppId
