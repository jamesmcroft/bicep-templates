@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

type skuInfo = {
  name: 'B1' | 'B2' | 'B3' | 'F1' | 'S1' | 'S2' | 'S3'
  capacity: int
}

@description('IoT Hub SKU. Defaults to F1, 1 unit.')
param sku skuInfo = {
  name: 'F1'
  capacity: 1
}

type storageTelemetryConfigInfo = {
  name: string?
  storageAccountName: string
  containerName: string
  batchFrequencyInSeconds: int?
  maxChunkSizeInBytes: int?
  encoding: 'json' | 'avro'?
  fileNameFormat: string?
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
        storageContainers: storageTelemetryConfig.storageAccountName != '' && storageTelemetryConfig.containerName != '' ? [
          {
            name: storageTelemetryConfig.name
            connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageTelemetryConfig.storageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', storageTelemetryConfig.storageAccountName), '2022-05-01').keys[0].value};EndpointSuffix=core.windows.net'
            containerName: storageTelemetryConfig.containerName
            batchFrequencyInSeconds: storageTelemetryConfig.batchFrequencyInSeconds
            maxChunkSizeInBytes: storageTelemetryConfig.maxChunkSizeInBytes
            fileNameFormat: storageTelemetryConfig.fileNameFormat
            encoding: storageTelemetryConfig.encoding
          }
        ] : []
      }
    }
  }
}

@description('The resource ID of the IoT Hub resource.')
output iotHubId string = iotHub.id
