@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@export()
@description('SKU information for IoT Hub DPS.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'B1' | 'B2' | 'B3' | 'F1' | 'S1' | 'S2' | 'S3'
  @description('Number of units in the SKU.')
  capacity: int
}

@description('IoT Hub DPS SKU. Defaults to F1, 1 unit.')
param sku skuInfo = {
  name: 'F1'
  capacity: 1
}
@description('Name for the IoT Hub associated with the DPS.')
param iotHubName string

resource iotHub 'Microsoft.Devices/IotHubs@2022-04-30-preview' existing = {
  name: iotHubName
}

resource iotHubDps 'Microsoft.Devices/provisioningServices@2022-02-05' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    iotHubs: [
      {
        connectionString: 'HostName=${iotHub.properties.hostName};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listkeys().value[0].primaryKey}'
        location: iotHub.location
      }
    ]
  }
}

@description('The deployed IoT Hub DPS resource.')
output resource resource = iotHubDps
@description('ID for the deployed IoT Hub DPS resource.')
output id string = iotHubDps.id
@description('Name for the deployed IoT Hub DPS resource.')
output name string = iotHubDps.name
