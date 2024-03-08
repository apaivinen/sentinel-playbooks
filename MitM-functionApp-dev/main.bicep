targetScope = 'resourceGroup'

@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Required. Name for the Azure Function App.')
@maxLength(64)
param name string = 'fa-20240308-dev2'

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Optional. Tags for all resources within Azure Function App module.')
param tags object = {resource:name}

var storageAccountName = toLower(replace('${name}-storage','-',''))

//
// Load and create a storage account
//
module storage 'modules/storageaccount/main.bicep' = {
  name: storageAccountName
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    storageAccountName: storageAccountName
    tags:tags
  }
}


module function_app 'modules/functionapp/main.bicep' = {
  name: name
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    storage
  ]
  params: {
    name: name
    location: location
    storageAccountKey: storage.outputs.storageAccountKey
    storageAccountName: storage.outputs.storageAccountName
    tags:tags
  }
}
