targetScope = 'resourceGroup'

@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Required. Name for the Azure Function App.')
@maxLength(64)
param name string = 'fa-20240308-dev3'

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Optional. Tags for all resources within Azure Function App module.')
param tags object = {resource:name}

var storageAccountName = toLower(replace('${name}-storage','-',''))

//
// Load and create a storage account
//
module Storage 'modules/storageaccount/main.bicep' = {
  name: storageAccountName
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    storageAccountName: storageAccountName
    tags:tags
  }
}

module AppServicePlan 'modules/appserviceplan/main.bicep' = {
  name: name
  scope: resourceGroup(resourceGroupName)
  params:{
    name: name
    location: location
    tags: tags
  }
}

module function_app 'modules/functionapp/main.bicep' = {
  name: name
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    Storage
    AppServicePlan
  ]
  params: {
    name: name
    location: location
    storageAccountName: Storage.outputs.storageAccountName
    tags:tags
    serverfarmsId: AppServicePlan.outputs.serverfarmsId
  }
}
