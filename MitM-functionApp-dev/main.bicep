metadata name = 'MitM busting Apps'
metadata description = 'This bicep deploys sentinel man in the middle playbook resources.'
metadata author = 'Anssi Päivinen'
metadata Created = '2024-03-19'

targetScope = 'resourceGroup'

@description('Define a prefix to be attached to every service name. For example customer name abreviation')
param servicePrefix string  = 'Anssi'

@description('Required. General name of the service.')
param name string = 'MitM'

@description('The name of the target environment (e.g. "production")')
param deploymentEnvironment string = 'dev'

@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Optional. Tags for all resources within Azure Function App module.')
param tags object = {resource:'${servicePrefix}-${name}-${deploymentEnvironment}'}

var storageAccountName = take(toLower(replace('${servicePrefix}${name}${deploymentEnvironment}${substring(uniqueString(deployment().name, location), 0, 4)}','-','')),24)
var AppServiceName = '${servicePrefix}-${name}-AppService-${deploymentEnvironment}'
var functionAppName = '${servicePrefix}-${name}-FuncApp-${deploymentEnvironment}'

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

//
// Load and create a App service plan
//
module AppServicePlan 'modules/appserviceplan/main.bicep' = {
  name: AppServiceName
  scope: resourceGroup(resourceGroupName)
  params:{
    name: AppServiceName
    location: location
    tags: tags
  }
}

//
// Load and create a function App
//
module functionApp 'modules/web/site/main.bicep'= {
  name: functionAppName
  dependsOn:[
    Storage
    AppServicePlan
  ]
  scope: resourceGroup(resourceGroupName)
  params: {
    name: functionAppName
    location: location
    serverFarmResourceId: AppServicePlan.outputs.serverfarmsId
    kind: 'functionapp'
    tags: tags
  }
}

/*
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
*/
