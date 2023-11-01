@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
    name: 'Premium_LRS' | 'Premium_ZRS' | 'Standard_GRS' | 'Standard_GZRS' | 'Standard_LRS' | 'Standard_RAGRS' | 'Standard_RAGZRS' | 'Standard_ZRS'
}

@description('Storage Account SKU. Defaults to Standard_LRS.')
param sku skuInfo = {
    name: 'Standard_LRS'
}

@description('Access tier for the Storage Account. If the sku is a premium SKU, this will be ignored. Defaults to Hot.')
@allowed([
    'Hot'
    'Cool'
])
param accessTier string = 'Hot'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
    name: name
    location: location
    tags: tags
    kind: 'StorageV2'
    sku: sku
    properties: {
        accessTier: startsWith(sku.name, 'Premium') ? 'Premium' : accessTier
        networkAcls: {
            bypass: 'AzureServices'
            defaultAction: 'Allow'
        }
        supportsHttpsTrafficOnly: true
        encryption: {
            services: {
                blob: {
                    enabled: true
                }
                file: {
                    enabled: true
                }
                table: {
                    enabled: true
                }
                queue: {
                    enabled: true
                }
            }
            keySource: 'Microsoft.Storage'
        }
    }
}

@description('ID for the deployed Storage Account resource.')
output id string = storageAccount.id
@description('Name for the deployed Storage Account resource.')
output name string = storageAccount.name
@description('Connection string (without account key) for the deployed Storage Account resource.')
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};'
