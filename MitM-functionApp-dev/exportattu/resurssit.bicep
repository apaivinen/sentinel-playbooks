param subscriptionId string
param name string
param location string
param use32BitWorkerProcess bool
param ftpsState string
param storageAccountName string
param netFrameworkVersion string
param sku string
param skuCode string
param workerSize string
param workerSizeId string
param numberOfWorkers string
param hostingPlanName string
param serverFarmResourceGroup string
param alwaysOn bool

resource name_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: name
  kind: 'functionapp'
  location: location
  tags: {}
  properties: {
    name: name
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
          value: '1'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id,'2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id,'2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'devmitmbustingappbe93'
        }
      ]
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
      use32BitWorkerProcess: use32BitWorkerProcess
      ftpsState: ftpsState
      netFrameworkVersion: netFrameworkVersion
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    serverFarmId: '/subscriptions/${subscriptionId}/resourcegroups/${serverFarmResourceGroup}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
  }
  dependsOn: [hostingPlan]
}

resource name_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: name_resource
  name: 'scm'
  properties: {
    allow: false
  }
}

resource name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: name_resource
  name: 'ftp'
  properties: {
    allow: false
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanName
  location: location
  kind: ''
  tags: {}
  properties: {
    name: hostingPlanName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
  }
  sku: {
    tier: sku
    name: skuCode
  }
  dependsOn: []
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  tags: {}
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    defaultToOAuthAuthentication: true
  }
}
