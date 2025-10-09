targetScope = 'subscription'

///// PARAMETERS /////

@description('Azure region used for the deployment of all resources')
param location string

@description('Abbreviation fo the location')
param location_abbreviation string

@description('Name of the workload that will be deployed')
param workload string

@description('Name of the workloads environment')
param environment string

@description('Tags to be applied on the resource group')
param tags object

///// VARIABLES /////

var rg_name = 'rg-${workload}-${environment}-${location_abbreviation}'

var rg_tags_final = union({
    workload: workload
    environment: environment
  }, tags)

///// MODULES /////

module rg 'modules/resourceGroup.bicep' = {
  name: 'rg-${workload}-${environment}-deployment'
  params: {
    name: rg_name
    location: location
    tags: rg_tags_final
  }
}

///// OUTPUTS /////
output resource_groups array = [ rg_name ]
