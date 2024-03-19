metadata name = 'MitM busting Apps'
metadata description = 'This bicep deploys sentinel man in the middle playbook resources.'
metadata author = 'Anssi Päivinen'
metadata Created = '2024-03-19'

targetScope = 'resourceGroup'

//
// Deployment specific parameters. Modify values based on your needs
//
@description('Define a prefix to be attached to every service name. For example customer name abreviation')
param servicePrefix string  = 'Anssi'

@description('Required. General name of the service.')
param name string = 'MitM'

@description('The name of the target environment (e.g. "dev" or "prod")')
param deploymentEnvironment string = 'dev'

//
// Optional and dynamic parameters. Change only if necessary
//
@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Optional. Tags for all resources within Azure Function App module.')
param tags object = {resource:'${servicePrefix}-${name}-${deploymentEnvironment}'}

@description('Required. Type of function app to deploy.')
@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
  'functionapp,workflowapp' // logic app workflow
  'functionapp,workflowapp,linux' // logic app docker container
  'app' // normal web app
])
param FunctionAppkind string = 'functionapp'

//
// Variables
//
var storageAccountName = take(toLower(replace('${servicePrefix}${name}${deploymentEnvironment}${substring(uniqueString(deployment().name, location), 0, 4)}','-','')),24)
var AppServiceName = '${servicePrefix}-${name}-AppService-${deploymentEnvironment}'
var functionAppName = '${servicePrefix}-${name}-FuncApp-${deploymentEnvironment}'
var functionAppWebsiteContentShare = toLower('${functionAppName}${substring(uniqueString(deployment().name, location), 0, 4)}')

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
    kind: FunctionAppkind
    tags: tags
    // Non-required parameters
    appSettingsKeyValuePairs: {
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${Storage.outputs.storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${Storage.outputs.storageAccountKey}'
      AzureFunctionsJobHost__logging__logLevel__default: 'Trace'
      EASYAUTH_SECRET: '<EASYAUTH_SECRET>'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${Storage.outputs.storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${Storage.outputs.storageAccountKey}'
      WEBSITE_CONTENTSHARE: functionAppWebsiteContentShare
    }
    basicPublishingCredentialsPolicies: [
      {
        allow: false
        name: 'ftp'
      }
      {
        allow: false
        name: 'scm'
      }
    ]
    storageAccountResourceId: Storage.outputs.storageAccountId
    storageAccountUseIdentityAuthentication: true
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
