@description('Name of the Virtual Network')
param vnetName string

@description('Location for the VNet')
param location string

@description('Address space for the VNet')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet configuration')
param subnets array = [
  {
    name: 'default'
    prefix: '10.0.1.0/24'
  }
  {
    name: 'storage'
    prefix: '10.0.2.0/24'
  }
  {
    name: 'functions'
    prefix: '10.0.3.0/24'
  }
  {
    name: 'private-endpoints'
    prefix: '10.0.4.0/24'
  }
]

@description('Tags for resources')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.prefix
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
  tags: tags
}

output subnet_ids object = {
  'private-endpoints': vnet.properties.subnets[3].id
  'default': vnet.properties.subnets[0].id
  'storage': vnet.properties.subnets[1].id
  'functions': vnet.properties.subnets[2].id
}
output vnet_id string = vnet.id
