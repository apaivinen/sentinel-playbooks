metadata name = 'MitM busting Apps'
metadata description = 'This bicep deploys sentinel man in the middle playbook resources.'
metadata author = 'Anssi Päivinen'
metadata Created = '2024-03-19'

targetScope = 'resourceGroup'

//
// Deployment specific parameters. Modify values based on your needs
//
@description('Required. Define a prefix to be attached to every service name. For example customer name abreviation')
param servicePrefix string  = 'Leik'

@description('Required. General name of the service.')
param name string = 'MitM'

@description('Required. The name of the target environment (e.g. "dev" or "prod")')
param deploymentEnvironment string = 'dev'

@description('Required. Contains function app configs. Defaults are OK, modify values if needed')
param siteConfigs object = {
  numberOfWorkers: 1
      defaultDocuments: [
        'Default.htm'
        'Default.html'
        'Default.asp'
        'index.htm'
        'index.html'
        'iisstart.htm'
        'default.aspx'
        'index.php'
      ]
      netFrameworkVersion: 'v6.0'
      requestTracingEnabled: false
      remoteDebuggingEnabled: false
      httpLoggingEnabled: false
      acrUseManagedIdentityCreds: false
      logsDirectorySizeLimit: 35
      detailedErrorLoggingEnabled: false
      publishingUsername: ''
      scmType: 'None'
      use32BitWorkerProcess: true
      webSocketsEnabled: false
      alwaysOn: false
      managedPipelineMode: 'Integrated'
      virtualApplications: [
        {
          virtualPath: '/'
          physicalPath: 'site\\wwwroot'
          preloadEnabled: false
        }
      ]
      loadBalancing: 'LeastRequests'
      experiments: {
        rampUpRules: []
      }
      autoHealEnabled: false
      vnetRouteAllEnabled: false
      vnetPrivatePortsCount: 0
      publicNetworkAccess: 'Enabled'
      cors: {
        allowedOrigins: ['https://portal.azure.com']
        supportCredentials: false
      }
      localMySqlEnabled: false
      ipSecurityRestrictions: [
        {
          ipAddress: 'Any'
          action: 'Allow'
          priority: 2147483647
          name: 'Allow all'
          description: 'Allow all access'
        }
      ]
      ipSecurityRestrictionsDefaultAction: 'Allow'
      scmIpSecurityRestrictions: [
        {
          ipAddress: 'Any'
          action: 'Deny'
          priority: 2147483647
          name: 'Deny all'
          description: 'Deny all access'
        }
      ]
      scmIpSecurityRestrictionsDefaultAction: 'Deny'
      scmIpSecurityRestrictionsUseMain: false
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      preWarmedInstanceCount: 0
      functionAppScaleLimit: 200
      functionsRuntimeScaleMonitoringEnabled: false
      minimumElasticInstanceCount: 0
      azureStorageAccounts: {}
}
//
// Optional and dynamic parameters. Change only if necessary
//
@description('Define a name for resource group')
param resourceGroupName string = resourceGroup().name

@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Tags for all resources within Azure Function App module.')
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
var AppServiceName = replace('${servicePrefix}-${name}-AppServ-${deploymentEnvironment}',' ','')
var functionAppName = replace('${servicePrefix}-${name}-FuncApp-${deploymentEnvironment}',' ','')
var functionAppWebsiteContentShare = replace(toLower('${functionAppName}${substring(uniqueString(deployment().name, location), 0, 4)}'),' ','')
var logicAppName =  replace('${servicePrefix}-${name}-CssDetection-LogicApp-${deploymentEnvironment}',' ','')
var logAnalyticsConnectorName = replace('${servicePrefix}-${name}-LogAnalyticsConnector-${deploymentEnvironment}',' ','')


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
    siteConfig: siteConfigs
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
module connector 'modules/connector/main.bicep'={
  name: logAnalyticsConnectorName
  scope: resourceGroup(resourceGroupName)
  params:{
    location: location
    logAnalyticsConnName: logAnalyticsConnectorName
    tags:tags
  }
}
//
// Load and create a Logic App
//
module logicApp 'modules/logicapp/main.bicep' = {
  name: logicAppName
  dependsOn: [
    functionApp
    connector
  ]
  scope: resourceGroup(resourceGroupName)
  params:{
    logicAppName: logicAppName
    location: location
    resourceGroupName: resourceGroupName
    logAnalyticsConnName: logAnalyticsConnectorName 
    tags: tags
  }
}
