@description('Name of the resource.')
param name string
@description('Tags for the resource.')
param tags object = {}

type aRecordInfo = {
  @description('Name of the A record.')
  name: string
  @description('TTL for the A record.')
  ttl: int
  @description('IPv4 address for the A record.')
  ipv4Address: string
}

@description('Name of the virtual network to which the DNS zone will be linked.')
param virtualNetworkName string
@description('The list of A records to be created in the DNS zone.')
param aRecords aRecordInfo[] = []

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: virtualNetworkName
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags
  properties: {}
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZone.name}-${virtualNetwork.name}-link'
  location: 'global'
  tags: tags
  parent: dnsZone
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: true
  }
}

resource aRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = [for aRecord in aRecords: {
  name: aRecord.name
  parent: dnsZone
  properties: {
    ttl: aRecord.ttl
    aRecords: [
      {
        ipv4Address: aRecord.ipv4Address
      }
    ]
  }
}]

@description('The deployed DNS Zone resource.')
output resource resource = dnsZone
@description('ID for the deployed DNS Zone resource.')
output id string = dnsZone.id
@description('Name for the deployed DNS Zone resource.')
output name string = dnsZone.name
@description('The deployed DNS Zone virtual network link resource.')
output linkResource resource = link
@description('ID for the deployed DNS Zone virtual network link resource.')
output linkId string = link.id
@description('Name for the deployed DNS Zone virtual network link resource.')
output linkName string = link.name
