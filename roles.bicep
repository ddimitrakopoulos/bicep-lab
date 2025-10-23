targetScope = 'resourceGroup'

@description('List of role assignments to create. Each object should include principalId and roleDefinitionId.')
param roleAssignments array

resource roleAssigns 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignments: {
  name: guid(resourceGroup().id, assignment.principalId, assignment.roleDefinitionId)
  scope: resourceGroup()
  properties: {
    principalId: assignment.principalId
    roleDefinitionId: assignment.roleDefinitionId
  }
}]

// ----------------------
// Outputs
// ----------------------
output createdRoleAssignments array = [for assignment in roleAssignments: {
  name: guid(resourceGroup().id, assignment.principalId, assignment.roleDefinitionId)
  principalId: assignment.principalId
  roleDefinitionId: assignment.roleDefinitionId
}]

