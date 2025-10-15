param peName string
param location string
param subnetId string
param privateLinkServiceId string
param groupIds array
param dnsZoneId string
param dnsGroupName string = 'dns-group'
param connectionName string = 'connection'

resource pe 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: peName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: connectionName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
    privateDnsZoneGroups: [
      {
        name: dnsGroupName
        properties: {
          privateDnsZoneConfigs: [
            {
              name: '${dnsGroupName}Config'
              properties: {
                privateDnsZoneId: dnsZoneId
              }
            }
          ]
        }
      }
    ]
  }
}

output peId string = pe.id
