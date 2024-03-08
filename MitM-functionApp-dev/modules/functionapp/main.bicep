targetScope = 'resourceGroup'

/*param section*/
@description('Required. Name for the Azure Function App.')
@maxLength(64)
param name string

@description('Required. Location for all resources.')
param location string

@description('Optional. Tags for all resources within Azure Function App module.')
param tags object = {}

@description('ServerfarmId from app service plan')
param serverfarmsId string

@allowed(['None', 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned'
])
@description('Optional. The type of identity used for the virtual machine. The type \'SystemAssigned, UserAssigned\' includes both an implicitly created identity and a set of user assigned identities. The type \'None\' will remove any identities from the sites ( app or functionapp).')
param identityType string = 'SystemAssigned'

@description('Optional. Specify the resource ID of the user assigned Managed Identity, if \'identity\' is set as \'UserAssigned\'.')
param userAssignedIdentityId string = ''

@description('Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests.')
param httpsOnly bool = true

@description('Optional. The resource ID of the app service environment to use for this resource.')
param appServiceEnvironmentId string = ''

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Required. Type of site to deploy.')
@allowed([ 'functionapp', 'app' ])
param kind string = 'functionapp'

@description('Optional. Version of the function extension.')
param functionsExtensionVersion string = '~4'

@description('Dictates whether editing in the Azure portal is enabled.')
@allowed(['readonly', 'readwrite'])
param functionAppEditMode string = 'readwrite'

@description('Optional. Runtime of the function worker. WARNING: NOT ALL OSes SUPPORT ALL RUNTIMES!')
@allowed(['dotnet', 'node', 'python', 'java', 'powershell', ''])
param functionsWorkerRuntime string = 'dotnet'

@description('Optional. NodeJS version.')
param functionsDefaultNodeversion string = '~14'

@allowed([ 'Disabled', 'Enabled' ])
@description('Optional. The network access type for accessing Application Insights ingestion. - Enabled or Disabled.')
param publicNetworkAccessForIngestion string = 'Enabled'

@allowed([ 'Disabled', 'Enabled' ])
@description('Optional. The network access type for accessing Application Insights query. - Enabled or Disabled.')
param publicNetworkAccessForQuery string = 'Enabled'

@description('Optional. Application type.')
@allowed([ 'web', 'other' ])
param appInsightsType string = 'web'

@description('Optional. The kind of application that this component refers to, used to customize UI.')
param appInsightsKind string = 'azfunc'

@description('Optional. Enabled or Disable Insights for Azure functions.')
param enableInsights bool = false

@description('Optional. Resource ID of the log analytics workspace which the data will be ingested to, if enableaInsights is false.')
param workspaceResourceId string = ''

@description('Optional. List of Azure function (Actual object where our code resides).')
param functions functionType[] = []

@description('Optional. Enable Vnet Integration or not.')
param enableVnetIntegration bool = false

@description('Optional. The subnet that will be integrated to enable vnet Integration.')
param subnetId string = ''

@description('Optional. Enable Source control for the function.')
param enableSourceControl bool = false

@description('Optional. Repository or source control URL.')
param repoUrl string = ''

@description('Optional. Name of branch to use for deployment.')
param branch string = 'main'

@description('Required. Name of the storage account used by function app.')
@secure()
param storageAccountName string

@description('Optional. to limit to manual integration; to enable continuous integration (which configures webhooks into online repos like GitHub).')
param isManualIntegration bool = true

@description('Optional. true for a Mercurial repository; false for a Git repository.')
param isMercurial bool = false

@description('Required. Resource Group of storage account used by function app.')
param storageAccountResourceGroup string = resourceGroup().name

@description('Optional. True to deploy functions from zip package. "functionPackageUri" must be specified if enabled. The package option and sourcecontrol option should not be enabled at the same time.')
param enablePackageDeploy bool = false

@description('Optional. URI to the function source code zip package, must be accessible by the deployer. E.g. A zip file on Azure storage in the same resource group.')
param functionPackageUri string = ''

@description('Optional. Enable docker image deployment.')
param enableDockerContainer bool = false

@description('Optional. This will be required when enableDockerContainer passed as true.')
param dockerImage string = ''

@description('''Optional. Extra app settings that should be provisioned while creating the function app. Note! Settings below should not be included unless absolutely necessary, because settings in this param will override the ones added by the module:
AzureWebJobsStorage
AzureWebJobsDashboard
WEBSITE_CONTENTSHARE
WEBSITE_CONTENTAZUREFILECONNECTIONSTRING
FUNCTIONS_EXTENSION_VERSION
FUNCTIONS_WORKER_RUNTIME
WEBSITE_NODE_DEFAULT_VERSION
APPINSIGHTS_INSTRUMENTATIONKEY
APPLICATIONINSIGHTS_CONNECTION_STRING''')
param extraAppSettings object = {}

@description('The state of FTP / FTPS service.')
@allowed(['Disabled', 'AllAllowed', 'FtpsOnly'])
param ftpsState string = 'Disabled'

@description('Configures the minimum version of TLS required for SSL requests.')
@allowed(['1.0', '1.1', '1.2'])
param minTlsVersion string = '1.2'

@description('Linux App Framework and version. e.g. PYTHON|3.9')
param linuxFxVersion string = ''

@description('The connection strings properties')
param connectionStringProperties object = {}

@description('Defines storageAccounts for Azure Function App.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
  scope: resourceGroup(storageAccountResourceGroup)
}

// TÄSTÄ ON POISTETTU resource serverfarms 'Microsoft.Web/serverfarms@2021-02-01'

@description('If enabled, this will help monitor the application using the log analytics workspace.')
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (enableInsights) {
  name: 'ai-${name}'
  location: location
  kind: appInsightsKind
  properties: {
    Application_Type: appInsightsType
    WorkspaceResourceId: workspaceResourceId
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  }
  tags: tags
}

@description('''The app or function app resource.
Note: This is not actual Azure Function App this will be container for storing multiple functions.''')
resource sites 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  identity: {
    type: identityType
    userAssignedIdentities: (identityType == 'UserAssigned' || identityType == 'SystemAssigned, UserAssigned') ? {
      '${userAssignedIdentityId}': {}
    } : null
  }
  properties: {
    siteConfig: {
      linuxFxVersion: enableDockerContainer ? 'DOCKER|${dockerImage}' : linuxFxVersion ?? null
      ftpsState: ftpsState
      minTlsVersion: minTlsVersion
    }
    serverFarmId: serverfarmsId
    httpsOnly: httpsOnly
    hostingEnvironmentProfile: !empty(appServiceEnvironmentId) ? {
      id: appServiceEnvironmentId
    } : null
    clientAffinityEnabled: clientAffinityEnabled
  }
}

@description('Appsettings/config for the sites (app or functionapp).')
resource config 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: sites
  name: 'appsettings'
  properties: union({
      AzureWebJobsStorage: !empty(storageAccount.id) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};' : any(null)
      AzureWebJobsDashboard: !empty(storageAccount.id) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};' : any(null)
      WEBSITE_CONTENTSHARE: name
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: !empty(storageAccount.id) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};' : any(null)
      FUNCTIONS_EXTENSION_VERSION: functionsExtensionVersion
      FUNCTION_APP_EDIT_MODE: functionAppEditMode
      FUNCTIONS_WORKER_RUNTIME: sites.kind == 'functionapp' && !empty(functionsWorkerRuntime) ? functionsWorkerRuntime : any(null)
      WEBSITE_NODE_DEFAULT_VERSION: sites.kind == 'functionapp' && functionsWorkerRuntime == 'node' && !empty(functionsDefaultNodeversion) ? functionsDefaultNodeversion : any(null)
      APPINSIGHTS_INSTRUMENTATIONKEY: !empty(appInsights.id) && enableInsights ? appInsights.properties.InstrumentationKey : any(null)
      APPLICATIONINSIGHTS_CONNECTION_STRING: !empty(appInsights.id) && enableInsights ? appInsights.properties.ConnectionString : any(null)
    }, extraAppSettings)
  dependsOn: enableVnetIntegration ? [ networkConfig ] : []
}

resource connectionString 'Microsoft.Web/sites/config@2023-01-01' = if (!empty(connectionStringProperties)) {
  name: 'connectionstrings'
  kind: 'string'
  parent: sites
  properties: connectionStringProperties
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2023-01-01' = if (enableVnetIntegration == true) {
  parent: sites
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetId
  }
}

@description('The resources actual is function where code exits.')
resource azureFunction 'Microsoft.Web/sites/functions@2023-01-01' = {
  dependsOn: [
    config
  ]
  parent:sites
  name:'dnslookup'
  properties:{
    script_root_path_href:'https://${name}.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/'
    script_href: 'https://${name}.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/run.csx'
    config_href: 'https://${name}.azurewebsites.net/admin/vfs/site/wwwroot/dnslookup/function.json'
    test_data_href: 'https://${name}.azurewebsites.net/admin/vfs/data/Functions/sampledata/dnslookup.dat'
    href: 'https://${name}.azurewebsites.net/admin/functions/dnslookup'
    config: {}
    test_data: '{\r\n    "name": "Azure"\r\n}'
    invoke_url_template: 'https://${name}.azurewebsites.net/api/dnslookup'
    language: 'CSharp'
    isDisabled: false
  }
}

resource sourcecontrol 'Microsoft.Web/sites/sourcecontrols@2023-01-01' = if (enableSourceControl) {
  parent: sites
  name: 'web'
  properties: {
    repoUrl: repoUrl
    branch: branch
    isManualIntegration: isManualIntegration
    isMercurial: isMercurial
  }
}

@description('Deploy function app from zip file.')
resource extensions 'Microsoft.Web/sites/extensions@2023-01-01' = if (enablePackageDeploy) {
  parent: sites
  name: 'MSDeploy'
  properties: {
    packageUri: functionPackageUri
  }
}


resource hostname 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: sites
  name: '${name}.azurewebsites.net'
  properties: {
    siteName: name
    hostNameType: 'Verified'
  }
}

resource scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: sites
  name: 'scm'
  properties: {
    allow: false
  }
}

resource ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = {
  parent: sites
  name: 'ftp'
  properties: {
    allow: false
  }
}

/*output section*/
@description('Get resource id for app or functionapp.')
output siteId string = sites.id

@description('Get resource name for app or functionapp.')
output siteName string = sites.name

@description('Array of functions having name , language,isDisabled and id of functions.')
output functions array = [for function in functions: {
  name: function.name
  language: function.properties.language
  isDisabled: function.properties.isDisabled
  id: '${sites.id}/functions/${function.name}'
  files: function.properties.files
}]

@description('Principal Id of the identity assigned to the function app.')
output sitePrincipalId string = (sites.identity.type == 'SystemAssigned') ? sites.identity.principalId : ''


// user defined types
type functionType = {
  name: string
  properties: {
    language: string
    config: object
    isDisabled: bool
    files: object
  }
}
