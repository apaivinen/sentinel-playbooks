using './main.bicep'

param servicePrefix = 'Leikkikentta'
param name = 'MitM'
param deploymentEnvironment = 'dev'
param siteConfigs = {
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
  netFrameworkVersion: 'v8.0'
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
    allowedOrigins: [
      'https://portal.azure.com'
    ]
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
      ipAddress: '88.86.150.114/32'
      action: 'Allow'
      tag: 'Default'
      priority: 300
      name: 'anssi-ip'
      description: 'anssi'
    }
    {
      ipAddress: '194.100.36.100/32'
      action: 'Allow'
      tag: 'Default'
      priority: 301
      name: 'toimisto'
      description: 'tsto'
    }
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


