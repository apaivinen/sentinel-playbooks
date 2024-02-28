targetScope = 'resourceGroup'

@description('Define a prefix to be attached to every service name')
param servicePrefix string 

@description('Define a name for resource group')
param resourceGroupName string

@description('The name of the target environment (e.g. "production")')
param deploymentEnvironment string = 'dev'

@description('Specifies the location for resources.')
param location string = 'westeurope'

var storageAccountName = '${servicePrefix}general'

//
// Load and create a storage account
//
module storage 'modules/storageaccount/main.bicep' = {
  name: storageAccountName
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}


//
// Load and deploy two App ServicePlans for Linux and Windows to be used by further modules.
//
var appServiceKind = [{ skuName: 'B1', skuType: 'linux', skuTier: 'Basic', skuCapacity: 1}]
// , { skuName: 'Y1', skuType: 'functionapp', skuTier: 'Dynamic', skuCapacity: 0 }
module appServicePlan 'modules/appserviceplan/main.bicep' = [for ask in appServiceKind: {
  name: 'appServicePlan_${ask.skuType}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    appServiceKind: ask.skuType
    appServicePlanName: '${servicePrefix}-${ask.skuType}-asp-${deploymentEnvironment}'
    skuName: ask.skuName
    skuTier: ask.skuTier
    skuCapacity: ask.skuCapacity
  }
}]

//
// Load and deploy the Azure Functions module
//
var functionAppNames = ['attendees', 'attendeesbyorg', 'publiccourses', 'courses', 'mapping-appsetings']

module function_app 'modules/functionapp/main.bicep' = [for faName in functionAppNames: {
  name: '${servicePrefix}-fa-${faName}-${deploymentEnvironment}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    storage
    appServicePlan
  ]
  params: {
    appName: '${servicePrefix}-fa-${faName}-${deploymentEnvironment}'
    location: location
    appServicePlanId: appServicePlan[0].outputs.appServicePlanID // [0] is linuix, [1] is windows
    appInsightInstKey: ''
    storageAccountKey: storage.outputs.storageAccountKey
    storageAccountName: storage.outputs.storageAccountName
  }
}]
