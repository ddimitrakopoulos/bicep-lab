param nicName string
param subnetId string
param privateIp string = '' 
param nsgId string = '' 

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: empty(privateIp) ? 'Dynamic' : 'Static'
          privateIPAddress: privateIp
        }
      }
    ]
    networkSecurityGroup: empty(nsgId) ? null : { id: nsgId }
  }
}
