@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for IoT Hub.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'B1' | 'B2' | 'B3' | 'F1' | 'S1' | 'S2' | 'S3'
  @description('Number of units in the SKU.')
  capacity: int
}

@export()
@description('Information about the storage account to store raw telemetry data.')
type storageTelemetryConfigInfo = {
  @description('Name of the data.')
  name: string
  @description('Name of the storage account to store raw telemetry data.')
  storageAccountName: string
  @description('Name of the container to store raw telemetry data.')
  containerName: string
  @description('Frequency in seconds to batch the data.')
  batchFrequencyInSeconds: int?
  @description('Maximum size of the chunk in bytes.')
  maxChunkSizeInBytes: int?
  @description('Encoding of the data.')
  encoding: 'json' | 'avro'?
  @description('Format of the file name.')
  fileNameFormat: string?
}

@description('IoT Hub SKU. Defaults to F1, 1 unit.')
param sku skuInfo = {
  name: 'F1'
  capacity: 1
}
@description('Storage Account configuration to store raw telemetry data.')
param storageTelemetryConfig storageTelemetryConfigInfo = {
  name: 'Telemetry'
  storageAccountName: ''
  containerName: ''
  batchFrequencyInSeconds: 100
  maxChunkSizeInBytes: 104857600
  encoding: 'json'
  fileNameFormat: '{iothub}/{partition}/{YYYY}-{MM}-{DD}/{HH}-{mm}'
}

resource iotHub 'Microsoft.Devices/IotHubs@2022-04-30-preview' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    routing: {
      endpoints: {
        storageContainers: storageTelemetryConfig.storageAccountName != '' && storageTelemetryConfig.containerName != ''
          ? [
              {
                name: storageTelemetryConfig.name
                connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageTelemetryConfig.storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageTelemetryConfig.storageAccountName), '2022-05-01').keys[0].value};EndpointSuffix=core.windows.net'
                containerName: storageTelemetryConfig.containerName
                batchFrequencyInSeconds: storageTelemetryConfig.batchFrequencyInSeconds
                maxChunkSizeInBytes: storageTelemetryConfig.maxChunkSizeInBytes
                fileNameFormat: storageTelemetryConfig.fileNameFormat
                encoding: storageTelemetryConfig.encoding
              }
            ]
          : []
      }
    }
  }
}

@description('The deployed IoT Hub resource.')
output resource resource = iotHub
@description('ID for the deployed IoT Hub resource.')
output id string = iotHub.id
@description('Name for the deployed IoT Hub resource.')
output name string = iotHub.name
@description('Endpoint for the deployed IoT Hub resource.')
output hostName string = iotHub.properties.hostName
