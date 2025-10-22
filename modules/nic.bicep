@description('Name of the network interface')
param nicName string

@description('Subnet resource ID')
param subnetId string

@description('Static private IP (optional)')
param privateIp string = ''

@description('Network security group ID (optional)')
param nsgId string = ''

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: empty(privateIp) ? 'Dynamic' : 'Static'
          ...(empty(privateIp) ? {} : { privateIPAddress: privateIp })
        }
      }
    ]
    ...(empty(nsgId) ? {} : {
      networkSecurityGroup: {
        id: nsgId
      }
    })
  }
}

